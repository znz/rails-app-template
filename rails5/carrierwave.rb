# -*- coding: utf-8 -*-
# frozen_string_literal: true

require_relative 'util'

gem_bundle 'carrierwave'
gem_bundle 'mini_magick'

append_file 'config/locales/attributes.ja.yml', <<-'YAML'.b
    attachment: "添付画像"
    remove_attachment: "添付画像を削除"
YAML
create_file 'config/locales/carrierwave.ja.yml', <<-'YAML'
ja:
  errors:
    messages:
      carrierwave_processing_error: 処理できませんでした
      carrierwave_integrity_error: は許可されていないファイルタイプです
      carrierwave_download_error: はダウンロードできません
      extension_white_list_error: "%{extension}ファイルのアップロードは許可されていません。アップロードできるファイルタイプ: %{allowed_types}"
      extension_black_list_error: "%{extension}ファイルのアップロードは許可されていません。アップロードできないファイルタイプ: %{prohibited_types}"
      rmagick_processing_error: "rmagickがファイルを処理できませんでした。画像を確認してください。エラーメッセージ: %{e}"
      mime_types_processing_error: "MIME::Typesのファイルを処理できませんでした。Content-Typeを確認してください。エラーメッセージ: %{e}"
      mini_magick_processing_error: "MiniMagickがファイルを処理できませんでした。画像を確認してください。エラーメッセージ: %{e}"
      content_type_whitelist_error: "%{content_type}ファイルのアップロードは許可されていません。"
YAML
initializer 'carrierwave.rb', <<-'RUBY'
CarrierWave.configure do |config|
  # use directly shared/uploads instead of realeases/*/uploads for X-Sendfile
  begin
    config.root = (Rails.root+'uploads').realpath + Rails.env
  rescue Errno::ENOENT
    config.root = Rails.root + 'uploads' + Rails.env
  end
  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  end
  CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
end
RUBY
append_file '.gitignore', "\n\# Ignore uploaded files.\n/uploads/\n"

generate 'uploader', 'attachment'
git_commit 'Generate attachment uploader'
uncomment_lines 'app/uploaders/attachment_uploader.rb', /include CarrierWave::MiniMagick/
gsub_file 'app/uploaders/attachment_uploader.rb', '"uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"', '"#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"'
gsub_file 'app/uploaders/attachment_uploader.rb', /.*version :thumb do\n.*\n.*\n/, <<-'RUBY'
  version :thumb do
    process :resize_to_fit => [200, 200]
  end
RUBY
gsub_file 'app/uploaders/attachment_uploader.rb', /.*def extension_white_list\n.*\n.*\n/, <<-'RUBY'
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def content_type_whitelist
    [
      /\Aimage\//,
    ]
  end

  VERSIONS_PATTERN = /\A(?:#{self.versions.keys.join('|')})/
RUBY
insert_into_file 'app/models/ability.rb', <<-'RUBY', after: /def initialize\(user\)\n/
    alias_action :attachment, to: :read
RUBY
git_commit 'Update attachment uploader'

# for `fixture_file_upload('sample.png', 'image/png')` and
# `Rack::Test::UploadedFile.new(Rails.root + 'spec/fixtures/sample.png', 'image/png')`
create_file 'spec/fixtures/sample.png', ''
git_commit 'Add dummy image file'

create_file 'app/helpers/image_tag_helper.rb', <<-'RUBY'
# frozen_string_literal: true
module ImageTagHelper
  def attachment_image_tag(resource)
    thumb = resource.attachment_url(:thumb).to_s
    url = resource.attachment_url.to_s
    link_to image_tag(thumb, alt: File.basename(url)), url, data: { turbolinks: false }
  end
end
RUBY
create_file 'app/controllers/concerns/attachment_downloader.rb', <<-'RUBY'
module AttachmentDownloader
  def attachment
    filename = params.permit(:filename, :id, :format)[:filename]
    AttachmentUploader::VERSIONS_PATTERN =~ filename
    resource = instance_variable_get('@'+self.class.controller_name.singularize)
    send_uploaded resource.attachment, $&
  end

  private def send_uploaded(uploaded, version = nil)
    uploaded = uploaded.__send__(version) if version
    path = uploaded.url
    path = URI.unescape(path)
    send_uploaded_under(uploaded.root, path)
  end

  private def send_uploaded_under(root, path)
    path = File.expand_path("#{root}#{path}")
    if path.start_with?(root.to_s) && File.exist?(path)
      case path
      when /\.jpe?g\z/i
        content_type = 'image/jpeg'
      when /\.png\z/i
        content_type = 'image/png'
      when /\.gif\z/i
        content_type = 'image/gif'
      when /\.pdf\z/i
        content_type = 'application/pdf'
      end
      response_expires(1.hour)
      send_file path, disposition: 'inline', type: content_type
    else
      render file: Rails.root.join('public/404.html'), status: 404, layout: false, content_type: 'text/html'
    end
  end

  private def response_expires(duration)
    response.headers['Cache-Control'] = "private, max-age=#{duration.to_i}"
    response.headers['Expires'] = duration.from_now.gmtime.strftime '%a, %d %b %Y %H:%M:%S %Z'
  end
end
RUBY
create_file 'app/controllers/uploads_controller.rb', <<-'RUBY'
class UploadsController < ApplicationController
  include AttachmentDownloader

  ROOT = Rails.root+'uploads'+Rails.env

  def tmp
    tmp_params = params.permit(:filename, :id, :format)
    send_uploaded_under(ROOT, "/uploads/tmp/#{tmp_params[:id]}/#{tmp_params[:filename]}.#{tmp_params[:format]}")
  end
end
RUBY
route %q(get 'uploads/tmp/:id/*filename' => 'uploads#tmp')
git_commit 'Download cache attachment'

gsub_file 'lib/templates/slim/scaffold/_form.html.slim', '  = f.<%= attribute.reference? ? :association : :input %> :<%= attribute.name %>', <<-'SLIM'
  <%- case attribute.name -%>
  <%- when /attachment/ -%>
  .form-group
    = f.label :attachment, class: 'control-label col-sm-3'
    .col-sm-9
      = f.input_field :attachment
      = f.hidden_field :attachment_cache
      .preview
        - if f.object.attachment?
          = attachment_image_tag f.object
          /= f.input :remove_attachment, hint: attachment_image_tag(f.object), as: :boolean
  <%- else -%>
  = f.<%= attribute.reference? ? :association : :input %> :<%= attribute.name %>
  <%- end -%>
SLIM
git_commit 'Update attachment form'

create_file 'app/assets/javascripts/preview.coffee', <<-'COFFEE'
jQuery ->
  preview = (e) ->
    if !FileReader
      return false
    $preview = $(e.target).closest('.form-group').find('.preview')
    if e.target.files.length < 1
      $preview.empty()
      return false
    file = e.target.files[0]
    reader = new FileReader
    if file.type.indexOf('image') < 0
      $preview.empty()
      return false
    onload = (file) ->
      return (e) ->
        $preview.empty()
        img = $('<img>')
        img.attr
          src: e.target.result
          width: "200px"
          class: "preview"
          title: file.name
        $preview.append img
    reader.onload = onload(file)
    reader.readAsDataURL(file)
  $(document).on 'turbolinks:load', ->
    $('form').on 'change', 'input[type="file"]', preview

COFFEE
git_commit 'Add preview'
