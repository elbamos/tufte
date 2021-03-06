% Please edit documentation in R/handout.R, R/html.R, R/utils.R
\name{tufte_handout}
\alias{margin_note}
\alias{newthought}
\alias{quote_footer}
\alias{sans_serif}
\alias{tufte_handout}
\alias{tufte_html}
\title{Tufte handout formats (PDF and HTML)}
\usage{
tufte_handout(fig_width = 4, fig_height = 2.5, fig_crop = TRUE, dev = "pdf", 
    highlight = "default", ...)

tufte_html(...)

newthought(text)

margin_note(text, icon = "&#8853;")

quote_footer(text)

sans_serif(text)
}
\arguments{
\item{fig_width}{Default width (in inches) for figures}

\item{fig_height}{Default width (in inches) for figures}

\item{fig_crop}{\code{TRUE} to automatically apply the \code{pdfcrop} utility
(if available) to pdf figures}

\item{dev}{Graphics device to use for figure output (defaults to pdf)}

\item{highlight}{Syntax highlighting style. Supported styles include
"default", "tango", "pygments", "kate", "monochrome", "espresso",
"zenburn", and "haddock". Pass \code{NULL} to prevent syntax highlighting.}

\item{...}{Other arguments to be passed to \code{\link{pdf_document}} or
\code{\link{html_document}} (note you cannot use the \code{template}
argument in \code{tufte_handout} or the \code{theme} argument in
\code{tufte_html()}; these arguments have been set internally)}

\item{text}{A character string to be presented as a \dQuote{new thought}
(using small caps), or a margin note, or a footer of a quote}

\item{icon}{A character string to indicate there is a hidden margin note when
the page width is too narrow (by default it is a circled plus sign)}
}
\description{
Templates for creating handouts according to the style of Edward R. Tufte and
Richard Feynman.
}
\details{
\code{tufte_handout()} provides the PDF format based on the Tufte-LaTeX
class: \url{https://tufte-latex.github.io/tufte-latex/}.

\code{tufte_html()} provides the HTML format based on the Tufte CSS:
  \url{https://edwardtufte.github.io/tufte-css/}.

\code{newthought()} can be used in inline R expressions in R
  Markdown (e.g. \samp{`r newthought(Some text)`}), and it works for both
  HTML (\samp{<span class="newthought">text</span>}) and PDF
  (\samp{\\newthought{text}}) output.

\code{margin_note()} can be used in inline R expressions to write a
  margin note (like a sidenote but not numbered).

\code{quote_footer()} formats text as the footer of a quote. It puts
  \code{text} in \samp{<footer></footer>} for HTML output, and
  after \samp{\\hfill} for LaTeX output (to right-align text).

\code{sans_serif()} applies sans-serif fonts to \code{text}.
}
\examples{
library(tufte)
newthought("In this section")
}
