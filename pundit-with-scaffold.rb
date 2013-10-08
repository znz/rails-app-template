# -*- coding: utf-8 -*-
Dir.glob('app/controllers/*_controller.rb') do |path|
  case path
  when /\/application_controller\.rb/
    next
  when %r!\Aapp/controllers/(.+)s_controller\.rb\z!
    model_name = $1
    generate "pundit:policy #{model_name}"
    insert_into_file path, <<-RUBY, before: /^  before_action :set_#{model_name}/
  before_action :authorize_#{model_name}, except: [:show, :edit, :update, :destroy]
    RUBY
    insert_into_file path, <<-RUBY, after: /^  private\n/
    def authorize_#{model_name}
      authorize #{model_name.classify}
    end

    RUBY
    insert_into_file path, <<-RUBY, after: /@#{model_name} = \w+\.find\(params\[:id\]\)\n/
      authorize @#{model_name}
    RUBY
  end
end
