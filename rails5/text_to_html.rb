# -*- coding: utf-8 -*-
# frozen_string_literal: true

require_relative 'util'

create_file 'app/helpers/text_to_html_helper.rb', <<-'RUBY'
# -*- coding: utf-8 -*-
# frozen_string_literal: true
module TextToHtmlHelper
  module_function

  TABLE_FOR_TEXT_TO_HTML__ = {
    "'" => '&#39;',
    '&' => '&amp;',
    '"' => '&quot;',
    '<' => '&lt;',
    '>' => '&gt;',
    "\r" => '',
    "\n" => "<br />\n",
    "&nbsp;" => "\u00A0",
  }
  TABLE_FOR_TEXT_TO_HTML__.default_proc = proc do |hash, key|
    uri = key
    begin
      URI.parse(uri) # validate
      "<a class=\"noreflink\">#{uri}</a>"
    rescue
      uri
    end
  end

  def text_to_html_content(text)
    text.gsub(%r{&nbsp;|[&<>"\r\n]|https?://[!-~]+}, TABLE_FOR_TEXT_TO_HTML__).html_safe
  end

  def text_to_html(text)
    html = text_to_html_content(text)
    content_tag(:div, html, class: 'text-to-html', data: { turbolinks: false })
  end
end
RUBY
create_file 'app/assets/javascripts/textlink.coffee', <<-'COFFEE'
jQuery ->
  noreflink = ->
    $('a.noreflink').each ->
      e = $(this)
      href = e.text()
      e.attr
        rel: "noreferrer"
        href: href
      found = href.match(/^https?:\/\/(www\.youtube\.com\/watch\?v=|youtu\.be\/)([^?&;]+)/)
      if found
        vid = found[2]
        unless e.next("div.video-container")[0]
          e.after('<div class="video-container"><iframe width="560" height="315" src="//www.youtube.com/embed/'+vid+'" frameborder="0" allowfullscreen></iframe></div>')
  $(document).on 'turbolinks:load', noreflink
COFFEE
git_commit 'Convert text to html and auto-link'
