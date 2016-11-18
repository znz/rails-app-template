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
    if %r[\A(?<pre>.)?(?<uri>https?://[!-~]+)\z] =~ key
      post = nil
      if pre == '(' && uri[-1] == ')'
        uri.chop!
        post = ')'
      end
      begin
        URI.parse(uri) # validate
        "#{pre}<a class=\"noreflink\">#{uri}</a>#{post}"
      rescue
        unless uri.empty?
          post = "#{uri[-1]}#{post}"
          uri.chop!
          retry
        end
        key
      end
    else
      key
    end
  end

  def text_to_html_content(text)
    text.gsub(%r{&nbsp;|['&<>"\r\n]|.?https?://[!-~]+}, TABLE_FOR_TEXT_TO_HTML__).html_safe
  end

  def text_to_html(text)
    html = text_to_html_content(text)
    content_tag(:div, html, class: 'text-to-html', data: { turbolinks: false })
  end
end
RUBY
create_file 'spec/helpers/text_to_html_helper_spec.rb', <<-'RUBY'
# -*- coding: utf-8 -*-
# frozen_string_literal: true
require 'rails_helper'

describe TextToHtmlHelper, type: :helper do
  include TextToHtmlHelper

  [
    ['', ''],
    ["'", '&#39;'],
    ['&', '&amp;'],
    ['&amp;', '&amp;amp;'],
    ['"', '&quot;'],
    ['<>', '&lt;&gt;'],
    ["\r", ''],
    ["\n", "<br />\n"],
    ["\r\n", "<br />\n"],
    ['&nbsp;', "\u00A0"],
    ['http://example.com/', '<a class="noreflink">http://example.com/</a>'],
    ['http://localhost:3000/', '<a class="noreflink">http://localhost:3000/</a>'],
    ['shttp://localhost:3000/', 's<a class="noreflink">http://localhost:3000/</a>'],
    ["\nhttp://localhost:3000/", "<br />\n<a class=\"noreflink\">http://localhost:3000/</a>"],
    ["http://localhost:3000/)", "<a class=\"noreflink\">http://localhost:3000/)</a>"],
    ["(http://localhost:3000/)", "(<a class=\"noreflink\">http://localhost:3000/</a>)"],
    ["[http://localhost:3000/]", "[<a class=\"noreflink\">http://localhost:3000/</a>]"],
    ["http://localhost:3000/]", "<a class=\"noreflink\">http://localhost:3000/</a>]"],
    ["[[http://localhost:3000/]]", "[[<a class=\"noreflink\">http://localhost:3000/</a>]]"],
  ].each do |input, output|
    it "text_to_html_content(#{input.dump}) should eq #{output.dump}" do
      expect(text_to_html_content(input)).to eq output
    end
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
