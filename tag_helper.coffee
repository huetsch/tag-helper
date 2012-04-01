root = exports ? this

String::dasherize = -> this.replace(/_/g, '-')

# XXX this function is a quick hack to translate TagHelper more easily. i'm pretty sure it doesn't actually ensure safety because it
# doesn't protect against unsafe string methods or concatenation (and we can't overload the + operator), but it's probably good
# enough for now
String::html_safe = ->
  this.is_html_safe = 1
  this

class TagHelper

  HTML_ESCAPE: { '&': '&amp;', '>': '&gt;', '<': '&lt;', '"': '&quot;' }
  JSON_ESCAPE: { '&': '\u0026', '>': '\u003E', '<': '\u003C' }

  # ==== Example:
  # puts html_escape("is a > 0 & a < 10?")
  # # => is a &gt; 0 &amp; a &lt; 10?
  html_escape: (s) ->
    unless s instanceof String
      s = String s
    unless s.is_html_safe?
      s.replace(/&/g, "&amp;").replace(/\"/g, "&quot;").replace(/>/g, "&gt;").replace(/</g, "&lt;").html_safe()
    else
      s

  BOOLEAN_ATTRIBUTES: [
    'disabled', 'readonly', 'multiple', 'checked', 'autobuffer', 'autoplay', 'controls', 'loop', 'selected', 'hidden', 'scoped',
    'async', 'defer', 'reversed', 'ismap', 'seemless', 'muted', 'required', 'autofocus', 'novalidate', 'formnovalidate', 'open',
    'pubdate'
  ]

  tag: (name, options = null, open = false, escape = true) ->
    tag_options = ''
    if options
      tag_options = @tag_options(options, escape)
    "<#{name}#{tag_options}#{if open then '>' else ' />'}".html_safe()

  content_tag: (name, content_or_options_with_block = null, options = null, escape = true) ->
    @content_tag_string(name, content_or_options_with_block, options, escape)

  content_tag_string: (name, content, options, escape = true) ->
    tag_options = if options then @tag_options(options, escape) else ''
    "<#{name}#{tag_options}>#{if escape then @html_escape(content) else content}</#{name}>".html_safe()

  tag_options: (options, escape = true) ->
    keys = (k for k, v of options)
    unless keys.length is 0
      attrs = []
      for key, value of options
        if key is 'data' and typeof value is 'object'
          for k, v of value
            unless typeof v is 'string'
              v = JSON.stringify v
            if escape
              v = @html_escape v
            attrs.push "data-#{k.dasherize()}=\"#{v}\""
        else if key in @BOOLEAN_ATTRIBUTES
          if value
            attrs.push "#{key}=\"#{key}\""
        else if (value isnt null and value isnt undefined)
          final_value = value
          if value instanceof Array
            final_value = value.join(" ")
          if escape
            final_value = @html_escape(final_value)
          attrs.push "#{key}=\"#{final_value}\""
      unless attrs.length is 0
        " #{attrs.sort().join(' ')}".html_safe()

helper = new TagHelper()

#class SafeBuffer extends String
  # not really sure why we need to override these values...
#  constructor: (__value__) ->
#    @dirty = false
#    @length = (@__value__ = __value__ or "").length
#    super __value__
#  toString: -> @__value__
#  valueOf: -> @__value__
#
#  is_dirty: ->
#    @dirty
#
#  is_html_safe: ->
#    not @dirty
#
#  concat: (other) ->
#    if @is_dirty() or other.is_html_safe()
#      super(other)
#    else
#      super(helper.html_escape(other))
#
 # XXX we can't overload operators in javascript
 #+: ->
 #  'a' + @__value__
#String::html_safe = -> new SafeBuffer(this.valueOf())

if window?
  window.TagHelper = helper
else
  root.html_escape = helper.html_escape
  root.tag = helper.tag
  root.content_tag = helper.content_tag_string
  root.tag_options = helper.tag_options