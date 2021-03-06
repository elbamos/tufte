#' @details \code{tufte_html()} provides the HTML format based on the Tufte CSS:
#'   \url{https://edwardtufte.github.io/tufte-css/}.
#' @rdname tufte_handout
#' @export
tufte_html = function(...) {

  format = rmarkdown::html_document(
    theme = NULL, ..., extra_dependencies = tufte_html_dependency()
  )

  # when fig.margin = TRUE, set fig.beforecode = TRUE so plots are moved before
  # code blocks, and they can be top-aligned
  ohooks = knitr::opts_hooks$set(fig.margin = function(options) {
    if (isTRUE(options$fig.margin)) options$fig.beforecode = TRUE
    options
  })

  # make sure the existing post processor is called first in our new processor
  post_processor = format$post_processor
  format$post_processor = function(metadata, input, output, clean, verbose) {

    if (is.function(post_processor))
      output = post_processor(metadata, input, output, clean, verbose)

    knitr::opts_hooks$restore(ohooks)

    x = readUTF8(output)
    footnotes = parse_footnotes(x)
    notes = footnotes$items
    # replace footnotes with sidenotes
    for (i in seq_along(notes)) {
      num = sprintf(
        '<a href="#fn%d" class="footnoteRef" id="fnref%d"><sup>%d</sup></a>',
        i, i, i
      )
      con = sprintf(paste0(
        '<label for="tufte-sn-%d" class="margin-toggle sidenote-number">%d</label>',
        '<input type="checkbox" id="tufte-sn-%d" class="margin-toggle">',
        '<span class="sidenote"><span class="sidenote-number">%d</span> %s</span>'
      ), i, i, i, i, notes[i])
      x = gsub_fixed(num, con, x)
    }
    # remove footnotes at the bottom
    if (length(footnotes$range)) x = x[-footnotes$range]

    # replace citations with margin notes
    x = margin_references(x)

    # place figure captions in margin notes
    x[x == '<p class="caption">'] = '<p class="caption marginnote shownote">'

    # place table captions in the margin
    r = '^<caption>(.+)</caption>$'
    for (i in grep(r, x)) {
      if (x[i - 1] != '<table>') next
      cap = gsub(r, '\\1', x[i])
      x[i] = '<table>'
      x[i - 1] = paste0(
        '<p><!--\n<caption>-->', '<span class="marginnote shownote">',
        cap, '</span><!--</caption>--></p>'
      )
    }

    # add an incremental number to the id of <label> and <input> for margin notes
    r = '(<label|<input type="checkbox") (id|for)(="tufte-mn)-(" )'
    mn = grep(r, x)
    for (i in seq_along(mn)) {
      x[mn[i]] = gsub(r, paste0('\\1 \\2\\3-', i, '\\4'), x[mn[i]])
    }
    writeUTF8(x, output)
    output
  }

  if (is.null(format$knitr$knit_hooks)) format$knitr$knit_hooks = list()
  format$knitr$knit_hooks$plot = function(x, options) {
    # make sure the plot hook always generates HTML code instead of ![]()
    if (is.null(options$out.extra)) options$out.extra = ''
    fig_margin = isTRUE(options$fig.margin)
    fig_fullwd = isTRUE(options$fig.fullwidth)
    if (fig_margin || fig_fullwd) {
      if (is.null(options$fig.cap)) options$fig.cap = ' ' # empty caption
    } else if (is.null(options$fig.topcaption)) {
      # for normal figures, place captions at the top of images
      options$fig.topcaption = TRUE
    }
    res = knitr::hook_plot_md(x, options)
    if (fig_margin) {
      res = gsub_fixed('<p class="caption">', '<!--\n<p class="caption marginnote">-->', res)
      res = gsub_fixed('</p>', '<!--</p>-->', res)
      res = gsub_fixed('</div>', '<!--</div>--></span></p>', res)
      res = gsub_fixed(
        '<div class="figure">', paste0(
          '<p>', '<span class="marginnote shownote">', '<!--\n<div class="figure">-->'
        ), res
      )
    } else if (fig_fullwd) {
      res = gsub_fixed('<div class="figure">', '<div class="figure fullwidth">', res)
      res = gsub_fixed(
        '<p class="caption">', '<p class="caption marginnote shownote">', res
      )
    }
    res
  }

  knitr::knit_engines$set(marginfigure = function(options) {
    options$type = 'marginnote'
    options$html.tag = 'span'
    options$html.before = marginnote_html()
    eng_block = knitr::knit_engines$get('block')
    eng_block(options)
  })

  format$inherits = 'html_document'

  format
}

#' @importFrom htmltools htmlDependency
tufte_html_dependency = function() {
  list(htmlDependency(
    'tufte-css', '2015.12.29',
    src = template_resources('tufte_html'), stylesheet = 'tufte.css'
  ))
}

# we assume one footnote only contains one paragraph here, although it is
# possible to write multiple paragraphs in a footnote with Pandoc's Markdown
parse_footnotes = function(x) {
  i = which(x == '<div class="footnotes">')
  if (length(i) == 0) return(list(items = character(), range = integer()))
  j = which(x == '</div>')
  j = min(j[j > i])
  n = length(x)
  r = '<li id="fn([0-9]+)"><p>(.+)<a href="#fnref\\1">.</a></p></li>'
  list(
    items = gsub(r, '\\2', grep(r, x[i:n], value = TRUE)),
    range = i:j
  )
}

# move reference items from the bottom to the margin (as margin notes)
margin_references = function(x) {
  i = which(x == '<div id="refs" class="references">')
  if (length(i) != 1) return(x)
  r = '^<div id="(ref-[^"]+?)">$'
  k = grep(r, x)
  k = k[k > i]
  n = length(k)
  if (n == 0) return(x)
  ids = gsub(r, '\\1', x[k])
  ids = sprintf('<a href="#%s">(.+?)</a>', ids)
  ref = gsub('^<p>|</p>$', '', x[k + 1])
  ref = marginnote_html(paste0('\\1<span class="marginnote">', ref, '</span>'))
  for (j in seq_len(n)) {
    x = gsub(ids[j], ref[j], x)
  }
  x[-(i:(max(k) + 3))]  # remove references at the bottom
}

marginnote_html = function(text = '', icon = '&#8853;') {
  sprintf(paste0(
    '<label for="tufte-mn-" class="margin-toggle">%s</label>',
    '<input type="checkbox" id="tufte-mn-" class="margin-toggle">%s'
  ), icon, text)
}
