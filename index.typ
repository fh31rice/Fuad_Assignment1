// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  pagenumbering: "1",
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#import "@preview/fontawesome:0.5.0": *

#show: doc => article(
  title: [CEVE 543 Fall 2025 Assignment 1 Fuad Hasan],
  subtitle: [Assignment 1],
  authors: (
    ( name: [James Doss-Gollin],
      affiliation: [],
      email: [] ),
    ),
  date: [2025-09-12],
  margin: (x: 1in,y: 1in,),
  fontsize: 11pt,
  sectionnumbering: "1.1.a",
  pagenumbering: "1",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Your Analysis
]
)
]
#block[
#callout(
body: 
[
== Loading Required Packages
<loading-required-packages>
First, we need to load all the Julia packages we'll use in this analysis:

== Loading NOAA Precipitation Data
<loading-noaa-precipitation-data>
Like previous labs, we'll download and read the Texas precipitation data:

#table(
  columns: 8,
  align: (right,right,left,left,left,right,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[stnid], table.cell(align: left)[noaa\_id], table.cell(align: left)[name], table.cell(align: left)[state], table.cell(align: left)[latitude], table.cell(align: left)[longitude], table.cell(align: left)[years\_of\_data],
    table.cell(align: right)[], table.cell(align: left)[Int64], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[Float64], table.cell(align: left)[Float64], table.cell(align: left)[Int64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: right)[1], table.cell(align: left)[60-0011], table.cell(align: left)[CLEAR CK AT BAY AREA BLVD], table.cell(align: left)[TX], table.cell(align: right)[29.4977], table.cell(align: right)[-95.1599], table.cell(align: right)[31],
  table.cell(align: right)[2], table.cell(align: right)[2], table.cell(align: left)[60-0019], table.cell(align: left)[TURKEY CK AT FM 1959], table.cell(align: left)[TX], table.cell(align: right)[29.5845], table.cell(align: right)[-95.1869], table.cell(align: right)[31],
  table.cell(align: right)[3], table.cell(align: right)[3], table.cell(align: left)[60-0022], table.cell(align: left)[ARMAND BYU AT GENOARED BLF RD], table.cell(align: left)[TX], table.cell(align: right)[29.6345], table.cell(align: right)[-95.1123], table.cell(align: right)[31],
  table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮],
  table.cell(align: right)[815], table.cell(align: right)[815], table.cell(align: left)[87-0031], table.cell(align: left)[SECO CREEK AT MILLER RANCH], table.cell(align: left)[TX], table.cell(align: right)[29.5731], table.cell(align: right)[-99.4028], table.cell(align: right)[20],
  table.cell(align: right)[816], table.cell(align: right)[816], table.cell(align: left)[99-2048], table.cell(align: left)[COTULLA], table.cell(align: left)[TX], table.cell(align: right)[28.4567], table.cell(align: right)[-99.2183], table.cell(align: right)[116],
)
#block[
#table(
  columns: 5,
  align: (right,right,left,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[stnid], table.cell(align: left)[date], table.cell(align: left)[year], table.cell(align: left)[rainfall],
    table.cell(align: right)[], table.cell(align: left)[Int64], table.cell(align: left)[Date], table.cell(align: left)[Int64], table.cell(align: left)[Quantity…?],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: right)[1], table.cell(align: left)[1987-06-11], table.cell(align: right)[1987], table.cell(align: right)[6.31 inch],
  table.cell(align: right)[2], table.cell(align: right)[1], table.cell(align: left)[1988-09-02], table.cell(align: right)[1988], table.cell(align: right)[5.46 inch],
  table.cell(align: right)[3], table.cell(align: right)[1], table.cell(align: left)[1989-08-01], table.cell(align: right)[1989], table.cell(align: right)[11.39 inch],
  table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮],
  table.cell(align: right)[61924], table.cell(align: right)[816], table.cell(align: left)[2016-08-20], table.cell(align: right)[2016], table.cell(align: right)[3.44 inch],
  table.cell(align: right)[61925], table.cell(align: right)[816], table.cell(align: left)[2017-09-25], table.cell(align: right)[2017], table.cell(align: right)[2.72 inch],
)
]
+ Check if data file already exists locally
+ Download the file if it doesn't exist
+ Read and parse the NOAA precipitation data

== Choosing Your Station- Task 1, part a, Select one Houston area for primary analysis
<choosing-your-station--task-1-part-a-select-one-houston-area-for-primary-analysis>
For GEV analysis, we need sufficient data. Let's examine stations with longer records:

#table(
  columns: 8,
  align: (right,right,left,left,left,right,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[stnid], table.cell(align: left)[noaa\_id], table.cell(align: left)[name], table.cell(align: left)[state], table.cell(align: left)[latitude], table.cell(align: left)[longitude], table.cell(align: left)[years\_of\_data],
    table.cell(align: right)[], table.cell(align: left)[Int64], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[Float64], table.cell(align: left)[Float64], table.cell(align: left)[Int64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: right)[112], table.cell(align: left)[41-0420], table.cell(align: left)[AUSTIN], table.cell(align: left)[TX], table.cell(align: right)[30.2682], table.cell(align: right)[-97.7426], table.cell(align: right)[169],
  table.cell(align: right)[2], table.cell(align: right)[600], table.cell(align: left)[41-7622], table.cell(align: left)[RIO GRANDE CITY], table.cell(align: left)[TX], table.cell(align: right)[26.3769], table.cell(align: right)[-98.8117], table.cell(align: right)[168],
  table.cell(align: right)[3], table.cell(align: right)[771], table.cell(align: left)[79-0043], table.cell(align: left)[BROWNSVILLE], table.cell(align: left)[TX], table.cell(align: right)[25.9156], table.cell(align: right)[-97.4186], table.cell(align: right)[168],
  table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮],
  table.cell(align: right)[9], table.cell(align: right)[303], table.cell(align: left)[41-3265], table.cell(align: left)[FT GRIFFIN], table.cell(align: left)[TX], table.cell(align: right)[32.9236], table.cell(align: right)[-99.2225], table.cell(align: right)[148],
  table.cell(align: right)[10], table.cell(align: right)[779], table.cell(align: left)[79-0055], table.cell(align: left)[GALVESTON], table.cell(align: left)[TX], table.cell(align: right)[29.3048], table.cell(align: right)[-94.7934], table.cell(align: right)[146],
)
+ Sort stations by years of data in descending order
+ Select the top 10 stations with most data

#strong[Choose YOUR OWN station for analysis. stnid 780 is chosen for assignment 1]

#block[
#block[
```
Selected station: 79-0056 - HOUSTON WB CITY
Years of data: 129
```

]
]
+ Filter rainfall data for your chosen station using station ID
+ Sort the data chronologically by date

#block[
#callout(
body: 
[
Let's visualize your chosen station's rainfall time series:

#box(image("index_files/figure-typst/cell-6-output-1.svg"))

= GEV Fitting: Multiple Approaches
<gev-fitting-multiple-approaches>
== Choosing Your Station- Task 1, part c, Implemnt MLE using maximum\_likelihood from Turing.jl and benchmark results against Extremes.jl for validation
<choosing-your-station--task-1-part-c-implemnt-mle-using-maximum_likelihood-from-turing.jl-and-benchmark-results-against-extremes.jl-for-validation>
=== side note: There are different GEV fit approach we learned in lab 3, the short note is, (a) MLE: Maximum likelihood estimator, Extremes.jl package is used and the function name is gevfit (b) Methods of moments with Extremes.jl, function is gevfitpwm (c) bayesian MLE approach using Turing.jl; function gevfitbayes; but we basically used gevfit(MLE metod approach) here as well…so this part of the ques says to compare (a) MLE vs (c)bayesian MLE
<side-note-there-are-different-gev-fit-approach-we-learned-in-lab-3-the-short-note-is-a-mle-maximum-likelihood-estimator-extremes.jl-package-is-used-and-the-function-name-is-gevfit-b-methods-of-moments-with-extremes.jl-function-is-gevfitpwm-c-bayesian-mle-approach-using-turing.jl-function-gevfitbayes-but-we-basically-used-gevfitmle-metod-approach-here-as-wellso-this-part-of-the-ques-says-to-compare-a-mle-vs-cbayesian-mle>
== MLE with Extremes.jl
<mle-with-extremes.jl>
First, let's fit a GEV distribution using maximum likelihood estimation (MLE) with #link("https://jojal5.github.io/Extremes.jl/stable/")[`Extremes.jl`];:

#block[
```
Extremes.jl GEV parameters:
```

]
```
Distributions.GeneralizedExtremeValue{Float64}(μ=3.2770237171577272, σ=1.190348323354834, ξ=0.2257264067321968)
```

+ Convert rainfall data to plain numbers, removing units and missing values
+ Fit GEV distribution using maximum likelihood estimation (MLE), part c task 1
+ Extract location parameter (μ) from the fitted model
+ Extract scale parameter (σ) from the fitted model
+ Extract shape parameter (ξ) from the fitted model
+ Create a distribution object for further analysis and plotting

== Method-of-Moments with Extremes.jl
<method-of-moments-with-extremes.jl>
Now let's try the method-of-moments approach using probability-weighted moments (PWM): this was not asked in he question but say we computed it

#block[
```
Extremes.jl PWM parameters:
```

]
```
Distributions.GeneralizedExtremeValue{Float64}(μ=3.268028474716475, σ=1.1842500849040243, ξ=0.2281780167421246)
```

+ Fit GEV distribution using probability-weighted moments (PWM) method
+ Extract location parameter (μ) from the PWM fitted model
+ Extract scale parameter (σ) from the PWM fitted model
+ Extract shape parameter (ξ) from the PWM fitted model
+ Create distribution object for PWM approach

== Bayesian Approach with Turing.jl for task c in part 1
<bayesian-approach-with-turing.jl-for-task-c-in-part-1>
Now let's implement a Bayesian approach using Turing.jl with wide priors:

#block[
```
Turing.jl GEV parameters (MLE):
```

]
```
Distributions.GeneralizedExtremeValue{Float64}(μ=3.277019149621373, σ=1.1903425017998241, ξ=0.2257274323787416)
```

+ Location parameter with wide prior
+ Log-scale parameter with wide prior (ensures positive scale)
+ Shape parameter with conservative prior around zero
+ Transform to positive scale parameter
+ Vectorized likelihood for the GEV distribution
+ Maximum likelihood estimation using updated Turing.jl syntax per #link("https://turinglang.org/docs/usage/mode-estimation/#controlling-the-optimisation-process")[docs]
+ Extract location parameter
+ Extract and transform scale parameter
+ Extract shape parameter
+ Create distribution object for analysis

== Comparing All Three Methods
<comparing-all-three-methods>
This part is Not required for the assignment 1, but let's compare

#table(
  columns: 5,
  align: (right,right,right,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[T\_years], table.cell(align: left)[Extremes\_MLE], table.cell(align: left)[Extremes\_PWM], table.cell(align: left)[Turing\_MLE],
    table.cell(align: right)[], table.cell(align: left)[Int64], table.cell(align: left)[Float64], table.cell(align: left)[Float64], table.cell(align: left)[Float64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: right)[5], table.cell(align: right)[5.4], table.cell(align: right)[5.39], table.cell(align: right)[5.4],
  table.cell(align: right)[2], table.cell(align: right)[10], table.cell(align: right)[6.77], table.cell(align: right)[6.75], table.cell(align: right)[6.77],
  table.cell(align: right)[3], table.cell(align: right)[25], table.cell(align: right)[8.86], table.cell(align: right)[8.85], table.cell(align: right)[8.86],
  table.cell(align: right)[4], table.cell(align: right)[50], table.cell(align: right)[10.73], table.cell(align: right)[10.72], table.cell(align: right)[10.73],
  table.cell(align: right)[5], table.cell(align: right)[100], table.cell(align: right)[12.9], table.cell(align: right)[12.9], table.cell(align: right)[12.9],
)
Now let's visualize all three fits together:

#box(image("index_files/figure-typst/cell-11-output-1.svg"))

#block[
```
  Activating project at `D:\FALL 2025\CEVE 543\assignment`
   Resolving package versions...
  No Changes to `D:\FALL 2025\CEVE 543\assignment\Project.toml`
  No Changes to `D:\FALL 2025\CEVE 543\assignment\Manifest.toml`
   Resolving package versions...
  No Changes to `D:\FALL 2025\CEVE 543\assignment\Project.toml`
  No Changes to `D:\FALL 2025\CEVE 543\assignment\Manifest.toml`
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 6}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 7}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_header :: Union{Tuple{AbstractString, Int64}, Tuple{AbstractString, Int64, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_rainfall_data :: Tuple{Vector{<:AbstractString}, Any, Int64}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.read_noaa_data :: Tuple{String}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.test_read_noaa_data :: Tuple{}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.calc_distance :: NTuple{4, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.weibull_plotting_positions :: Tuple{Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.find_nearest_stations :: Union{Tuple{Any, Any}, Tuple{Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.create_return_period_range :: Union{Tuple{}, Tuple{Any}, Tuple{Any, Any}, Tuple{Any, Any, Any}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
```

]
```
MersenneTwister(543)
```

```
gev_model (generic function with 2 methods)
```

```
load_or_sample (generic function with 1 method)
```

#block[
```
┌ Warning: Only a single thread available: MCMC chains are not sampled in parallel
└ @ AbstractMCMC C:\Users\Owner\.julia\packages\AbstractMCMC\nQLlh\src\sample.jl:410
Sampling (1 thread)   0%|█                              |  ETA: N/A
Sampling (1 thread)   0%|█                              |  ETA: 0:16:11
Sampling (1 thread)   1%|█                              |  ETA: 0:08:05
Sampling (1 thread)   2%|█                              |  ETA: 0:05:22
Sampling (1 thread)   2%|█                              |  ETA: 0:04:01
Sampling (1 thread)   2%|█                              |  ETA: 0:03:14
Sampling (1 thread)   3%|█                              |  ETA: 0:02:43
Sampling (1 thread)   4%|██                             |  ETA: 0:02:19
Sampling (1 thread)   4%|██                             |  ETA: 0:02:01
Sampling (1 thread)   4%|██                             |  ETA: 0:01:47
Sampling (1 thread)   5%|██                             |  ETA: 0:01:36
Sampling (1 thread)   6%|██                             |  ETA: 0:01:27
Sampling (1 thread)   6%|██                             |  ETA: 0:01:19
Sampling (1 thread)   6%|███                            |  ETA: 0:01:13
Sampling (1 thread)   7%|███                            |  ETA: 0:01:07
Sampling (1 thread)   8%|███                            |  ETA: 0:01:03
Sampling (1 thread)   8%|███                            |  ETA: 0:00:58
Sampling (1 thread)   8%|███                            |  ETA: 0:00:55
Sampling (1 thread)   9%|███                            |  ETA: 0:00:52
Sampling (1 thread)  10%|███                            |  ETA: 0:00:49
Sampling (1 thread)  10%|████                           |  ETA: 0:00:46
Sampling (1 thread)  10%|████                           |  ETA: 0:00:44
Sampling (1 thread)  11%|████                           |  ETA: 0:00:41
Sampling (1 thread)  12%|████                           |  ETA: 0:00:39
Sampling (1 thread)  12%|████                           |  ETA: 0:00:38
Sampling (1 thread)  12%|████                           |  ETA: 0:00:36
Sampling (1 thread)  13%|█████                          |  ETA: 0:00:34
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:33
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:32
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:31
Sampling (1 thread)  15%|█████                          |  ETA: 0:00:29
Sampling (1 thread)  16%|█████                          |  ETA: 0:00:28
Sampling (1 thread)  16%|█████                          |  ETA: 0:00:27
Sampling (1 thread)  16%|██████                         |  ETA: 0:00:26
Sampling (1 thread)  17%|██████                         |  ETA: 0:00:26
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:25
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:24
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:23
Sampling (1 thread)  19%|██████                         |  ETA: 0:00:22
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:22
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:21
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:20
Sampling (1 thread)  21%|███████                        |  ETA: 0:00:20
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:19
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:19
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:18
Sampling (1 thread)  23%|████████                       |  ETA: 0:00:18
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:17
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:17
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:20
Sampling (1 thread)  25%|████████                       |  ETA: 0:00:20
Sampling (1 thread)  26%|████████                       |  ETA: 0:00:19
Sampling (1 thread)  26%|█████████                      |  ETA: 0:00:19
Sampling (1 thread)  26%|█████████                      |  ETA: 0:00:18
Sampling (1 thread)  27%|█████████                      |  ETA: 0:00:18
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:18
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:17
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:17
Sampling (1 thread)  29%|█████████                      |  ETA: 0:00:16
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:16
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:16
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:15
Sampling (1 thread)  31%|██████████                     |  ETA: 0:00:15
Sampling (1 thread)  32%|██████████                     |  ETA: 0:00:15
Sampling (1 thread)  32%|██████████                     |  ETA: 0:00:14
Sampling (1 thread)  32%|███████████                    |  ETA: 0:00:14
Sampling (1 thread)  33%|███████████                    |  ETA: 0:00:14
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:13
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:13
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:13
Sampling (1 thread)  35%|███████████                    |  ETA: 0:00:13
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:12
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:12
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:12
Sampling (1 thread)  37%|████████████                   |  ETA: 0:00:12
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:11
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:11
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:11
Sampling (1 thread)  39%|█████████████                  |  ETA: 0:00:11
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:10
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:10
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:10
Sampling (1 thread)  41%|█████████████                  |  ETA: 0:00:10
Sampling (1 thread)  42%|█████████████                  |  ETA: 0:00:10
Sampling (1 thread)  42%|██████████████                 |  ETA: 0:00:09
Sampling (1 thread)  42%|██████████████                 |  ETA: 0:00:09
Sampling (1 thread)  43%|██████████████                 |  ETA: 0:00:09
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:09
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:09
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:09
Sampling (1 thread)  45%|██████████████                 |  ETA: 0:00:08
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:08
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:08
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:08
Sampling (1 thread)  47%|███████████████                |  ETA: 0:00:08
Sampling (1 thread)  48%|███████████████                |  ETA: 0:00:08
Sampling (1 thread)  48%|███████████████                |  ETA: 0:00:08
Sampling (1 thread)  48%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  49%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  51%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  52%|████████████████               |  ETA: 0:00:07
Sampling (1 thread)  52%|█████████████████              |  ETA: 0:00:07
Sampling (1 thread)  52%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  53%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  54%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  54%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  55%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  55%|██████████████████             |  ETA: 0:00:06
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:06
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:06
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:06
Sampling (1 thread)  57%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  57%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  58%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  58%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  59%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  61%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:05
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  63%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  65%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  67%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  68%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  68%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  68%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  69%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  71%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  73%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  74%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  74%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  74%|████████████████████████       |  ETA: 0:00:03
Sampling (1 thread)  75%|████████████████████████       |  ETA: 0:00:02
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:02
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:02
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:02
Sampling (1 thread)  77%|████████████████████████       |  ETA: 0:00:02
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  79%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  81%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  83%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  84%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  84%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  84%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  85%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  87%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  89%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  90%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  90%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  90%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  91%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  93%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  94%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  94%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  94%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  95%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  97%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  99%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread) 100%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread) 100%|███████████████████████████████| Time: 0:00:07
Sampling (1 thread) 100%|███████████████████████████████| Time: 0:00:08
[ Info: Sampled and cached prior samples to D:\FALL 2025\CEVE 543\assignment\prior_v1.nc
```

]
```
32000-element Vector{GeneralizedExtremeValue{Float64}}:
 Distributions.GeneralizedExtremeValue{Float64}(μ=1.4019821874419813, σ=1.5633084462528826, ξ=0.23103768398145547)
 Distributions.GeneralizedExtremeValue{Float64}(μ=5.913751485943754, σ=1.7413795280738866, ξ=0.1048418695549837)
 Distributions.GeneralizedExtremeValue{Float64}(μ=4.444057872970431, σ=1.9939871794202981, ξ=0.25845969346178427)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.993865776099194, σ=1.310968922438582, ξ=-0.08084862022014877)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.993865776099194, σ=1.310968922438582, ξ=-0.08084862022014877)
 Distributions.GeneralizedExtremeValue{Float64}(μ=6.0464387419984496, σ=1.5052667836647526, ξ=0.3108946342085578)
 Distributions.GeneralizedExtremeValue{Float64}(μ=5.8543015174733295, σ=1.8692088646890326, ξ=0.022092462600977025)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.8591426918339606, σ=1.629707988100022, ξ=0.1299015465621372)
 Distributions.GeneralizedExtremeValue{Float64}(μ=5.727038445490792, σ=2.253546592819908, ξ=0.0697909138244906)
 Distributions.GeneralizedExtremeValue{Float64}(μ=2.064375237960177, σ=1.5007811305932273, ξ=0.2012833909953048)
 ⋮
 Distributions.GeneralizedExtremeValue{Float64}(μ=4.822656682024173, σ=1.1447992778861618, ξ=0.053996101923635104)
 Distributions.GeneralizedExtremeValue{Float64}(μ=2.9885399001418604, σ=2.12758062871625, ξ=0.09762858192854625)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.880823031311745, σ=0.9436628105659727, ξ=0.03274977238596276)
 Distributions.GeneralizedExtremeValue{Float64}(μ=2.6247026338510264, σ=1.8181866914934945, ξ=-0.04118036772524741)
 Distributions.GeneralizedExtremeValue{Float64}(μ=5.487669157212406, σ=1.677687667927262, ξ=0.20562801597806946)
 Distributions.GeneralizedExtremeValue{Float64}(μ=5.487669157212406, σ=1.677687667927262, ξ=0.20562801597806946)
 Distributions.GeneralizedExtremeValue{Float64}(μ=4.382532759742311, σ=3.2486442457129012, ξ=0.2635219932389523)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.843639196112149, σ=0.8199269864445392, ξ=-0.05180252583652355)
 Distributions.GeneralizedExtremeValue{Float64}(μ=4.473238612243, σ=3.6173474713720792, ξ=0.13795174210988406)
```

#block[
```
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 6}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 7}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_header :: Union{Tuple{AbstractString, Int64}, Tuple{AbstractString, Int64, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_rainfall_data :: Tuple{Vector{<:AbstractString}, Any, Int64}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.read_noaa_data :: Tuple{String}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.test_read_noaa_data :: Tuple{}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.calc_distance :: NTuple{4, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.weibull_plotting_positions :: Tuple{Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.find_nearest_stations :: Union{Tuple{Any, Any}, Tuple{Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
```

]
#box(image("index_files/figure-typst/cell-16-output-2.svg"))

```
4-element Vector{ReturnLevelPrior}:
 ReturnLevelPrior(0.5, Distributions.InverseGamma{Float64}(
invd: Distributions.Gamma{Float64}(α=6.0, θ=0.06666666666666667)
θ: 15.0
)
)
 ReturnLevelPrior(0.9, Distributions.InverseGamma{Float64}(
invd: Distributions.Gamma{Float64}(α=6.0, θ=0.025)
θ: 40.0
)
)
 ReturnLevelPrior(0.98, Distributions.InverseGamma{Float64}(
invd: Distributions.Gamma{Float64}(α=6.0, θ=0.016666666666666666)
θ: 60.0
)
)
 ReturnLevelPrior(0.99, Distributions.InverseGamma{Float64}(
invd: Distributions.Gamma{Float64}(α=6.0, θ=0.0125)
θ: 80.0
)
)
```

```
gev_model_quantile_priors (generic function with 2 methods)
```

#block[
```
┌ Warning: Only a single thread available: MCMC chains are not sampled in parallel
└ @ AbstractMCMC C:\Users\Owner\.julia\packages\AbstractMCMC\nQLlh\src\sample.jl:410
Sampling (1 thread)   0%|█                              |  ETA: N/A
Sampling (1 thread)   0%|█                              |  ETA: 0:05:20
Sampling (1 thread)   1%|█                              |  ETA: 0:02:40
Sampling (1 thread)   2%|█                              |  ETA: 0:01:46
Sampling (1 thread)   2%|█                              |  ETA: 0:01:20
Sampling (1 thread)   2%|█                              |  ETA: 0:01:04
Sampling (1 thread)   3%|█                              |  ETA: 0:00:53
Sampling (1 thread)   4%|██                             |  ETA: 0:00:46
Sampling (1 thread)   4%|██                             |  ETA: 0:00:40
Sampling (1 thread)   4%|██                             |  ETA: 0:00:36
Sampling (1 thread)   5%|██                             |  ETA: 0:00:32
Sampling (1 thread)   6%|██                             |  ETA: 0:00:29
Sampling (1 thread)   6%|██                             |  ETA: 0:00:27
Sampling (1 thread)   6%|███                            |  ETA: 0:00:25
Sampling (1 thread)   7%|███                            |  ETA: 0:00:23
Sampling (1 thread)   8%|███                            |  ETA: 0:00:22
Sampling (1 thread)   8%|███                            |  ETA: 0:00:20
Sampling (1 thread)   8%|███                            |  ETA: 0:00:19
Sampling (1 thread)   9%|███                            |  ETA: 0:00:18
Sampling (1 thread)  10%|███                            |  ETA: 0:00:17
Sampling (1 thread)  10%|████                           |  ETA: 0:00:16
Sampling (1 thread)  10%|████                           |  ETA: 0:00:15
Sampling (1 thread)  11%|████                           |  ETA: 0:00:15
Sampling (1 thread)  12%|████                           |  ETA: 0:00:14
Sampling (1 thread)  12%|████                           |  ETA: 0:00:13
Sampling (1 thread)  12%|████                           |  ETA: 0:00:13
Sampling (1 thread)  13%|█████                          |  ETA: 0:00:12
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:12
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:12
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:11
Sampling (1 thread)  15%|█████                          |  ETA: 0:00:11
Sampling (1 thread)  16%|█████                          |  ETA: 0:00:10
Sampling (1 thread)  16%|█████                          |  ETA: 0:00:10
Sampling (1 thread)  16%|██████                         |  ETA: 0:00:10
Sampling (1 thread)  17%|██████                         |  ETA: 0:00:09
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:09
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:09
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:09
Sampling (1 thread)  19%|██████                         |  ETA: 0:00:08
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:08
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:08
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:08
Sampling (1 thread)  21%|███████                        |  ETA: 0:00:08
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:07
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:07
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:07
Sampling (1 thread)  23%|████████                       |  ETA: 0:00:07
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:07
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:07
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:07
Sampling (1 thread)  25%|████████                       |  ETA: 0:00:07
Sampling (1 thread)  26%|████████                       |  ETA: 0:00:07
Sampling (1 thread)  26%|█████████                      |  ETA: 0:00:07
Sampling (1 thread)  26%|█████████                      |  ETA: 0:00:06
Sampling (1 thread)  27%|█████████                      |  ETA: 0:00:06
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:06
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:06
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:06
Sampling (1 thread)  29%|█████████                      |  ETA: 0:00:06
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:06
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:06
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:05
Sampling (1 thread)  31%|██████████                     |  ETA: 0:00:05
Sampling (1 thread)  32%|██████████                     |  ETA: 0:00:05
Sampling (1 thread)  32%|██████████                     |  ETA: 0:00:05
Sampling (1 thread)  32%|███████████                    |  ETA: 0:00:05
Sampling (1 thread)  33%|███████████                    |  ETA: 0:00:05
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:05
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:05
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:05
Sampling (1 thread)  35%|███████████                    |  ETA: 0:00:05
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:05
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:04
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:04
Sampling (1 thread)  37%|████████████                   |  ETA: 0:00:04
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:04
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:04
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:04
Sampling (1 thread)  39%|█████████████                  |  ETA: 0:00:04
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:04
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:04
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:04
Sampling (1 thread)  41%|█████████████                  |  ETA: 0:00:04
Sampling (1 thread)  42%|█████████████                  |  ETA: 0:00:04
Sampling (1 thread)  42%|██████████████                 |  ETA: 0:00:04
Sampling (1 thread)  42%|██████████████                 |  ETA: 0:00:04
Sampling (1 thread)  43%|██████████████                 |  ETA: 0:00:03
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:03
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:03
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:03
Sampling (1 thread)  45%|██████████████                 |  ETA: 0:00:03
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:03
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:03
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:03
Sampling (1 thread)  47%|███████████████                |  ETA: 0:00:03
Sampling (1 thread)  48%|███████████████                |  ETA: 0:00:03
Sampling (1 thread)  48%|███████████████                |  ETA: 0:00:03
Sampling (1 thread)  48%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  49%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  51%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  52%|████████████████               |  ETA: 0:00:03
Sampling (1 thread)  52%|█████████████████              |  ETA: 0:00:03
Sampling (1 thread)  52%|█████████████████              |  ETA: 0:00:03
Sampling (1 thread)  53%|█████████████████              |  ETA: 0:00:03
Sampling (1 thread)  54%|█████████████████              |  ETA: 0:00:03
Sampling (1 thread)  54%|█████████████████              |  ETA: 0:00:02
Sampling (1 thread)  55%|█████████████████              |  ETA: 0:00:02
Sampling (1 thread)  55%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  57%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  57%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  58%|██████████████████             |  ETA: 0:00:02
Sampling (1 thread)  58%|███████████████████            |  ETA: 0:00:02
Sampling (1 thread)  59%|███████████████████            |  ETA: 0:00:02
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:02
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:02
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:02
Sampling (1 thread)  61%|███████████████████            |  ETA: 0:00:02
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  63%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:02
Sampling (1 thread)  65%|█████████████████████          |  ETA: 0:00:02
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:02
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:02
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:02
Sampling (1 thread)  67%|█████████████████████          |  ETA: 0:00:02
Sampling (1 thread)  68%|█████████████████████          |  ETA: 0:00:02
Sampling (1 thread)  68%|██████████████████████         |  ETA: 0:00:01
Sampling (1 thread)  68%|██████████████████████         |  ETA: 0:00:01
Sampling (1 thread)  69%|██████████████████████         |  ETA: 0:00:01
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:01
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:01
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:01
Sampling (1 thread)  71%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  73%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  74%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  74%|███████████████████████        |  ETA: 0:00:01
Sampling (1 thread)  74%|████████████████████████       |  ETA: 0:00:01
Sampling (1 thread)  75%|████████████████████████       |  ETA: 0:00:01
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:01
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:01
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:01
Sampling (1 thread)  77%|████████████████████████       |  ETA: 0:00:01
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  79%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:01
Sampling (1 thread)  81%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  83%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  84%|██████████████████████████     |  ETA: 0:00:01
Sampling (1 thread)  84%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  84%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  85%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  87%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:00
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:00
Sampling (1 thread)  89%|████████████████████████████   |  ETA: 0:00:00
Sampling (1 thread)  90%|████████████████████████████   |  ETA: 0:00:00
Sampling (1 thread)  90%|████████████████████████████   |  ETA: 0:00:00
Sampling (1 thread)  90%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  91%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  93%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  94%|█████████████████████████████  |  ETA: 0:00:00
Sampling (1 thread)  94%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  94%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  95%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  97%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  99%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread) 100%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread) 100%|███████████████████████████████| Time: 0:00:03
Sampling (1 thread) 100%|███████████████████████████████| Time: 0:00:03
[ Info: Sampled and cached samples to D:\FALL 2025\CEVE 543\assignment\prior_v2.nc
```

]
#box(image("index_files/figure-typst/cell-19-output-2.svg"))

```
Distributions.GeneralizedExtremeValue{Float64}(μ=3.3212771097479523, σ=1.2247591766877546, ξ=0.18108592435173576)
```

#block[
```
┌ Warning: Only a single thread available: MCMC chains are not sampled in parallel
└ @ AbstractMCMC C:\Users\Owner\.julia\packages\AbstractMCMC\nQLlh\src\sample.jl:410
Sampling (1 thread)   0%|█                              |  ETA: N/A
Sampling (1 thread)   0%|█                              |  ETA: 0:04:20
Sampling (1 thread)   1%|█                              |  ETA: 0:02:13
Sampling (1 thread)   2%|█                              |  ETA: 0:01:30
Sampling (1 thread)   2%|█                              |  ETA: 0:01:09
Sampling (1 thread)   2%|█                              |  ETA: 0:00:57
Sampling (1 thread)   3%|█                              |  ETA: 0:00:49
Sampling (1 thread)   4%|██                             |  ETA: 0:00:43
Sampling (1 thread)   4%|██                             |  ETA: 0:00:38
Sampling (1 thread)   4%|██                             |  ETA: 0:00:34
Sampling (1 thread)   5%|██                             |  ETA: 0:00:31
Sampling (1 thread)   6%|██                             |  ETA: 0:00:29
Sampling (1 thread)   6%|██                             |  ETA: 0:00:27
Sampling (1 thread)   6%|███                            |  ETA: 0:00:25
Sampling (1 thread)   7%|███                            |  ETA: 0:00:24
Sampling (1 thread)   8%|███                            |  ETA: 0:00:22
Sampling (1 thread)   8%|███                            |  ETA: 0:00:21
Sampling (1 thread)   8%|███                            |  ETA: 0:00:20
Sampling (1 thread)   9%|███                            |  ETA: 0:00:19
Sampling (1 thread)  10%|███                            |  ETA: 0:00:18
Sampling (1 thread)  10%|████                           |  ETA: 0:00:18
Sampling (1 thread)  10%|████                           |  ETA: 0:00:17
Sampling (1 thread)  11%|████                           |  ETA: 0:00:17
Sampling (1 thread)  12%|████                           |  ETA: 0:00:16
Sampling (1 thread)  12%|████                           |  ETA: 0:00:15
Sampling (1 thread)  12%|████                           |  ETA: 0:00:15
Sampling (1 thread)  13%|█████                          |  ETA: 0:00:14
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:14
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:14
Sampling (1 thread)  14%|█████                          |  ETA: 0:00:13
Sampling (1 thread)  15%|█████                          |  ETA: 0:00:13
Sampling (1 thread)  16%|█████                          |  ETA: 0:00:13
Sampling (1 thread)  16%|█████                          |  ETA: 0:00:12
Sampling (1 thread)  16%|██████                         |  ETA: 0:00:12
Sampling (1 thread)  17%|██████                         |  ETA: 0:00:12
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:12
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:11
Sampling (1 thread)  18%|██████                         |  ETA: 0:00:11
Sampling (1 thread)  19%|██████                         |  ETA: 0:00:11
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:11
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:10
Sampling (1 thread)  20%|███████                        |  ETA: 0:00:10
Sampling (1 thread)  21%|███████                        |  ETA: 0:00:10
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:10
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:10
Sampling (1 thread)  22%|███████                        |  ETA: 0:00:10
Sampling (1 thread)  23%|████████                       |  ETA: 0:00:09
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:09
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:09
Sampling (1 thread)  24%|████████                       |  ETA: 0:00:10
Sampling (1 thread)  25%|████████                       |  ETA: 0:00:10
Sampling (1 thread)  26%|████████                       |  ETA: 0:00:09
Sampling (1 thread)  26%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  26%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  27%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  28%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  29%|█████████                      |  ETA: 0:00:09
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:09
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:08
Sampling (1 thread)  30%|██████████                     |  ETA: 0:00:08
Sampling (1 thread)  31%|██████████                     |  ETA: 0:00:08
Sampling (1 thread)  32%|██████████                     |  ETA: 0:00:08
Sampling (1 thread)  32%|██████████                     |  ETA: 0:00:08
Sampling (1 thread)  32%|███████████                    |  ETA: 0:00:08
Sampling (1 thread)  33%|███████████                    |  ETA: 0:00:08
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:08
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:08
Sampling (1 thread)  34%|███████████                    |  ETA: 0:00:08
Sampling (1 thread)  35%|███████████                    |  ETA: 0:00:07
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  36%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  37%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  38%|████████████                   |  ETA: 0:00:07
Sampling (1 thread)  39%|█████████████                  |  ETA: 0:00:07
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:07
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:07
Sampling (1 thread)  40%|█████████████                  |  ETA: 0:00:06
Sampling (1 thread)  41%|█████████████                  |  ETA: 0:00:06
Sampling (1 thread)  42%|█████████████                  |  ETA: 0:00:06
Sampling (1 thread)  42%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  42%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  43%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  44%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  45%|██████████████                 |  ETA: 0:00:06
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:06
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:06
Sampling (1 thread)  46%|███████████████                |  ETA: 0:00:06
Sampling (1 thread)  47%|███████████████                |  ETA: 0:00:06
Sampling (1 thread)  48%|███████████████                |  ETA: 0:00:05
Sampling (1 thread)  48%|███████████████                |  ETA: 0:00:05
Sampling (1 thread)  48%|████████████████               |  ETA: 0:00:05
Sampling (1 thread)  49%|████████████████               |  ETA: 0:00:05
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:05
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:05
Sampling (1 thread)  50%|████████████████               |  ETA: 0:00:06
Sampling (1 thread)  51%|████████████████               |  ETA: 0:00:06
Sampling (1 thread)  52%|████████████████               |  ETA: 0:00:06
Sampling (1 thread)  52%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  52%|█████████████████              |  ETA: 0:00:06
Sampling (1 thread)  53%|█████████████████              |  ETA: 0:00:05
Sampling (1 thread)  54%|█████████████████              |  ETA: 0:00:05
Sampling (1 thread)  54%|█████████████████              |  ETA: 0:00:05
Sampling (1 thread)  55%|█████████████████              |  ETA: 0:00:05
Sampling (1 thread)  55%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  56%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  57%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  57%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  58%|██████████████████             |  ETA: 0:00:05
Sampling (1 thread)  58%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  59%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  60%|███████████████████            |  ETA: 0:00:05
Sampling (1 thread)  61%|███████████████████            |  ETA: 0:00:04
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  62%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  63%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  64%|████████████████████           |  ETA: 0:00:04
Sampling (1 thread)  65%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  66%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  67%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  68%|█████████████████████          |  ETA: 0:00:04
Sampling (1 thread)  68%|██████████████████████         |  ETA: 0:00:04
Sampling (1 thread)  68%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  69%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  70%|██████████████████████         |  ETA: 0:00:03
Sampling (1 thread)  71%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  72%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  73%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  74%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  74%|███████████████████████        |  ETA: 0:00:03
Sampling (1 thread)  74%|████████████████████████       |  ETA: 0:00:03
Sampling (1 thread)  75%|████████████████████████       |  ETA: 0:00:03
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:03
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:03
Sampling (1 thread)  76%|████████████████████████       |  ETA: 0:00:03
Sampling (1 thread)  77%|████████████████████████       |  ETA: 0:00:02
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  78%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  79%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  80%|█████████████████████████      |  ETA: 0:00:02
Sampling (1 thread)  81%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  82%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  83%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  84%|██████████████████████████     |  ETA: 0:00:02
Sampling (1 thread)  84%|███████████████████████████    |  ETA: 0:00:02
Sampling (1 thread)  84%|███████████████████████████    |  ETA: 0:00:02
Sampling (1 thread)  85%|███████████████████████████    |  ETA: 0:00:02
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:02
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  86%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  87%|███████████████████████████    |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  88%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  89%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  90%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  90%|████████████████████████████   |  ETA: 0:00:01
Sampling (1 thread)  90%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  91%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  92%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  93%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  94%|█████████████████████████████  |  ETA: 0:00:01
Sampling (1 thread)  94%|██████████████████████████████ |  ETA: 0:00:01
Sampling (1 thread)  94%|██████████████████████████████ |  ETA: 0:00:01
Sampling (1 thread)  95%|██████████████████████████████ |  ETA: 0:00:01
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  96%|██████████████████████████████ |  ETA: 0:00:00
Sampling (1 thread)  97%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  98%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread)  99%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread) 100%|███████████████████████████████|  ETA: 0:00:00
Sampling (1 thread) 100%|███████████████████████████████| Time: 0:00:09
Sampling (1 thread) 100%|███████████████████████████████| Time: 0:00:09
[ Info: Sampled and cached samples to D:\FALL 2025\CEVE 543\assignment\posterior_data.nc
```

]
```
32000-element Vector{GeneralizedExtremeValue{Float64}}:
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.157040556775922, σ=1.0793733047081946, ξ=0.21198362314937658)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.1894885477956243, σ=1.180578490906711, ξ=0.19901963840834783)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.3555554456686023, σ=1.1341796231563719, ξ=0.129480570133908)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.465958699202189, σ=1.2214234337899974, ξ=0.2240270990184996)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.0430850732266075, σ=1.1827904545787984, ξ=0.14004192960139944)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.31282386279497, σ=1.0564941200668014, ξ=0.21048996535746178)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.1245408207047856, σ=1.3919188913675655, ξ=0.2544323105142749)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.2691208126460354, σ=1.2988565865503137, ξ=0.2345844207024338)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.302740969201654, σ=1.1153827551796407, ξ=0.15539857889879952)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.181045145920242, σ=1.1428892436454845, ξ=0.13931302295851583)
 ⋮
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.2089451127950617, σ=1.0987919440123153, ξ=0.20442667136177892)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.1774136145006704, σ=1.2603946673603064, ξ=0.21685698370896403)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.3045248041906525, σ=1.2131643483352972, ξ=0.17007980628162675)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.164508996718147, σ=1.177741783867528, ξ=0.1959576267433321)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.302731222831372, σ=1.0960607078427296, ξ=0.19492817866580575)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.2445289744832153, σ=1.1358727795939563, ξ=0.19341406958505836)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.395928247792815, σ=1.2718634998714506, ξ=0.1495762635266941)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.4224241137873324, σ=1.1533972240431285, ξ=0.16474361371804355)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.4224241137873324, σ=1.1533972240431285, ξ=0.16474361371804355)
```

#box(image("index_files/figure-typst/cell-22-output-1.svg"))

#table(
  columns: 9,
  align: (left,right,right,left,right,right,right,right,right,),
  table.header(table.cell(align: left)[], table.cell(align: right)[mean], table.cell(align: right)[std], table.cell(align: left)[eti89], table.cell(align: right)[ess\_tail], table.cell(align: right)[ess\_bulk], table.cell(align: right)[rhat], table.cell(align: right)[mcse\_mean], table.cell(align: right)[mcse\_std],),
  table.hline(),
  table.cell(align: left)[μ], table.cell(align: right)[3.302], table.cell(align: right)[0.119], table.cell(align: left)[3.12 .. 3.49], table.cell(align: right)[21009], table.cell(align: right)[18672], table.cell(align: right)[1.00], table.cell(align: right)[0.00087], table.cell(align: right)[0.00061],
  table.cell(align: left)[ξ], table.cell(align: right)[0.1754], table.cell(align: right)[0.0531], table.cell(align: left)[0.0920 .. 0.262], table.cell(align: right)[21113], table.cell(align: right)[23535], table.cell(align: right)[1.00], table.cell(align: right)[0.00035], table.cell(align: right)[0.00028],
  table.cell(align: left)[log\_σ], table.cell(align: right)[0.200], table.cell(align: right)[0.0774], table.cell(align: left)[0.0776 .. 0.327], table.cell(align: right)[21946], table.cell(align: right)[18318], table.cell(align: right)[1.00], table.cell(align: right)[0.00057], table.cell(align: right)[0.00039],
)
#box(image("index_files/figure-typst/cell-24-output-1.svg"))

#box(image("index_files/figure-typst/cell-25-output-1.svg"))

== Task 2, part a -- Repeat Task 1 for 4 additional Houston-area stations using identical methods (pick one method from Task 1 - you don't need to do all three models), we will use MLE (gevfit) Extremes.jl
<task-2-part-a-repeat-task-1-for-4-additional-houston-area-stations-using-identical-methods-pick-one-method-from-task-1---you-dont-need-to-do-all-three-models-we-will-use-mle-gevfit-extremes.jl>
== Finding Nearest four Stations, so I choose one at the starting, now choose more 4…so total 5
<finding-nearest-four-stations-so-i-choose-one-at-the-starting-now-choose-more-4so-total-5>
#block[
```
Nearest stations to 79-0056:
```

]
#table(
  columns: 5,
  align: (right,left,left,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[noaa\_id], table.cell(align: left)[name], table.cell(align: left)[distance\_km], table.cell(align: left)[years\_of\_data],
    table.cell(align: right)[], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[Quantity…], table.cell(align: left)[Int64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: left)[79-0056], table.cell(align: left)[HOUSTON WB CITY], table.cell(align: right)[0.0 km], table.cell(align: right)[129],
  table.cell(align: right)[2], table.cell(align: left)[41-4321], table.cell(align: left)[HOUSTON HEIGHTS], table.cell(align: right)[7.22648 km], table.cell(align: right)[62],
  table.cell(align: right)[3], table.cell(align: left)[41-4326], table.cell(align: left)[HOUSTON-PORT], table.cell(align: right)[7.88331 km], table.cell(align: right)[29],
  table.cell(align: right)[4], table.cell(align: left)[41-4323], table.cell(align: left)[HOUSTON INDEP HTS], table.cell(align: right)[12.8861 km], table.cell(align: right)[75],
  table.cell(align: right)[5], table.cell(align: left)[41-4331], table.cell(align: left)[HOUSTON SPRING BRANCH], table.cell(align: right)[13.592 km], table.cell(align: right)[75],
)
+ Find the 4 geographically closest stations to your chosen station
+ Calculate distance in kilometers from your station to each nearby station
+ Select relevant columns for display: station ID, name, distance, and data years

== Fitting GEV to Multiple Stations
<fitting-gev-to-multiple-stations>
Let's fit GEV distributions to all stations (your chosen station plus the 4 nearest): To fit this we are choosing the MLE- Extremes.jl using gevfit because task 2, part a says to choose a method among MLE- Extremes.jl using gevfit or Methods of Moments with Extremes.jl or MLE using the Turing.jl workflow a Bayesian approach

+ Extract station ID first to avoid variable scoping issues
+ Filter rainfall data for this specific station
+ Sort the data chronologically by date
+ Apply the fitting function to each of the nearest stations
+ Extract the fitted GEV distribution objects from results
+ Extract station information (ID and years of data) from results

Let's visualize the geographic distribution of these stations:

#table(
  columns: 4,
  align: (right,left,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[noaa\_id], table.cell(align: left)[n\_years], table.cell(align: left)[RP50],
    table.cell(align: right)[], table.cell(align: left)[String], table.cell(align: left)[Int64], table.cell(align: left)[Float64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: left)[79-0056], table.cell(align: right)[125], table.cell(align: right)[10.7271],
  table.cell(align: right)[2], table.cell(align: left)[41-4321], table.cell(align: right)[57], table.cell(align: right)[11.5568],
  table.cell(align: right)[3], table.cell(align: left)[41-4326], table.cell(align: right)[29], table.cell(align: right)[26.2017],
  table.cell(align: right)[4], table.cell(align: left)[41-4323], table.cell(align: right)[73], table.cell(align: right)[12.5633],
  table.cell(align: right)[5], table.cell(align: left)[41-4331], table.cell(align: right)[67], table.cell(align: right)[13.0843],
)
#box(image("index_files/figure-typst/cell-29-output-1.svg"))

=== Task 3, part a: Nonstationarity analysis:
<task-3-part-a-nonstationarity-analysis>
== Conduct Mann-Kendall trend test on annual maxima; report test statistic, p-value, and interpretation
<conduct-mann-kendall-trend-test-on-annual-maxima-report-test-statistic-p-value-and-interpretation>
#block[
#block[
```
  Activating project at `D:\FALL 2025\CEVE 543\assignment\prblmset1`
```

]
]
#block[
#block[
```
    Updating `D:\FALL 2025\CEVE 543\assignment\prblmset1\Project.toml`
  [85f8d34a] - NCDatasets v0.14.8
    Updating `D:\FALL 2025\CEVE 543\assignment\prblmset1\Manifest.toml`
  [179af706] - CFTime v0.2.4
  [1fbeeb36] - CommonDataModel v0.3.10
  [3c3547ce] - DiskArrays v0.4.16
  [8ac3fa9e] - LRUCache v1.6.2
  [3da0fdf6] - MPIPreferences v0.1.11
  [85f8d34a] - NCDatasets v0.14.8
  [0b7ba130] - Blosc_jll v1.21.7+0
  [0234f1f7] - HDF5_jll v1.14.6+0
  [e33a78d0] - Hwloc_jll v2.12.2+0
  [7cb0a576] - MPICH_jll v4.3.1+0
  [f1f71cc9] - MPItrampoline_jll v5.5.4+0
  [9237b28f] - MicrosoftMPI_jll v10.1.4+3
  [7243133f] - NetCDF_jll v401.900.300+0
  [fe0851c0] - OpenMPI_jll v5.0.8+0
  [a65dc6b1] - Xorg_libpciaccess_jll v0.18.1+0
  [477f73a3] - libaec_jll v1.1.4+0
  [337d8026] - libzip_jll v1.11.3+0
      Active manifest files: 10 found
      Active artifact files: 124 found
      Active scratchspaces: 3 found
     Deleted no artifacts, repos, packages or scratchspaces
   Resolving package versions...
    Updating `D:\FALL 2025\CEVE 543\assignment\prblmset1\Project.toml`
  [85f8d34a] + NCDatasets v0.14.8
    Updating `D:\FALL 2025\CEVE 543\assignment\prblmset1\Manifest.toml`
  [179af706] + CFTime v0.2.4
⌅ [1fbeeb36] + CommonDataModel v0.3.10
  [3c3547ce] + DiskArrays v0.4.16
  [8ac3fa9e] + LRUCache v1.6.2
  [3da0fdf6] + MPIPreferences v0.1.11
  [85f8d34a] + NCDatasets v0.14.8
  [0b7ba130] + Blosc_jll v1.21.7+0
  [0234f1f7] + HDF5_jll v1.14.6+0
  [e33a78d0] + Hwloc_jll v2.12.2+0
  [7cb0a576] + MPICH_jll v4.3.1+0
  [f1f71cc9] + MPItrampoline_jll v5.5.4+0
  [9237b28f] + MicrosoftMPI_jll v10.1.4+3
  [7243133f] + NetCDF_jll v401.900.300+0
  [fe0851c0] + OpenMPI_jll v5.0.8+0
  [a65dc6b1] + Xorg_libpciaccess_jll v0.18.1+0
  [477f73a3] + libaec_jll v1.1.4+0
  [337d8026] + libzip_jll v1.11.3+0
        Info Packages marked with ⌅ have new versions available but compatibility constraints restrict them from upgrading. To see why use `status --outdated -m`
```

]
]
#block[
```
   Resolving package versions...
  No Changes to `D:\FALL 2025\CEVE 543\assignment\prblmset1\Project.toml`
  No Changes to `D:\FALL 2025\CEVE 543\assignment\prblmset1\Manifest.toml`
```

]
```
5
```

#block[
```
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 6}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 7}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_header :: Union{Tuple{AbstractString, Int64}, Tuple{AbstractString, Int64, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_rainfall_data :: Tuple{Vector{<:AbstractString}, Any, Int64}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.read_noaa_data :: Tuple{String}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.test_read_noaa_data :: Tuple{}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.calc_distance :: NTuple{4, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.weibull_plotting_positions :: Tuple{Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.find_nearest_stations :: Union{Tuple{Any, Any}, Tuple{Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.create_return_period_range :: Union{Tuple{}, Tuple{Any}, Tuple{Any, Any}, Tuple{Any, Any, Any}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
```

]
```
MersenneTwister(543)
```

#table(
  columns: 3,
  align: (right,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[year], table.cell(align: left)[log\_CO2],
    table.cell(align: right)[], table.cell(align: left)[Int64], table.cell(align: left)[Float64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: right)[1849], table.cell(align: right)[5.65312],
  table.cell(align: right)[2], table.cell(align: right)[1850], table.cell(align: right)[5.65407],
  table.cell(align: right)[3], table.cell(align: right)[1851], table.cell(align: right)[5.65452],
  table.cell(align: right)[⋮], table.cell(align: right)[⋮], table.cell(align: right)[⋮],
  table.cell(align: right)[175], table.cell(align: right)[2023], table.cell(align: right)[6.04281],
  table.cell(align: right)[176], table.cell(align: right)[2024], table.cell(align: right)[6.05116],
)
#box(image("index_files/figure-typst/cell-35-output-1.svg"))

#block[
#callout(
body: 
[
```
mann_kendall_test (generic function with 1 method)
```

== Man kendall result statistics for task 3 , part a
<man-kendall-result-statistics-for-task-3-part-a>
#table(
  columns: 11,
  align: (right,right,left,left,left,right,right,right,right,right,right,),
  table.header(table.cell(align: right)[Row], table.cell(align: left)[stnid], table.cell(align: left)[noaa\_id], table.cell(align: left)[name], table.cell(align: left)[state], table.cell(align: left)[latitude], table.cell(align: left)[longitude], table.cell(align: left)[years\_of\_data], table.cell(align: left)[distance\_km], table.cell(align: left)[mk\_S], table.cell(align: left)[mk\_pvalue],
    table.cell(align: right)[], table.cell(align: left)[Int64], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[String], table.cell(align: left)[Float64], table.cell(align: left)[Float64], table.cell(align: left)[Int64], table.cell(align: left)[Quantity…], table.cell(align: left)[Float64], table.cell(align: left)[Float64],),
  table.hline(),
  table.cell(align: right)[1], table.cell(align: right)[780], table.cell(align: left)[79-0056], table.cell(align: left)[HOUSTON WB CITY], table.cell(align: left)[TX], table.cell(align: right)[29.7622], table.cell(align: right)[-95.3593], table.cell(align: right)[129], table.cell(align: right)[0.0 km], table.cell(align: right)[651.0], table.cell(align: right)[0.165406],
  table.cell(align: right)[2], table.cell(align: right)[377], table.cell(align: left)[41-4321], table.cell(align: left)[HOUSTON HEIGHTS], table.cell(align: left)[TX], table.cell(align: right)[29.7914], table.cell(align: right)[-95.4261], table.cell(align: right)[62], table.cell(align: right)[7.22648 km], table.cell(align: right)[623.0], table.cell(align: right)[1.85426e-5],
  table.cell(align: right)[3], table.cell(align: right)[380], table.cell(align: left)[41-4326], table.cell(align: left)[HOUSTON-PORT], table.cell(align: left)[TX], table.cell(align: right)[29.7456], table.cell(align: right)[-95.28], table.cell(align: right)[29], table.cell(align: right)[7.88331 km], table.cell(align: right)[14.0], table.cell(align: right)[0.807343],
  table.cell(align: right)[4], table.cell(align: right)[378], table.cell(align: left)[41-4323], table.cell(align: left)[HOUSTON INDEP HTS], table.cell(align: left)[TX], table.cell(align: right)[29.8667], table.cell(align: right)[-95.4167], table.cell(align: right)[75], table.cell(align: right)[12.8861 km], table.cell(align: right)[336.0], table.cell(align: right)[0.110627],
  table.cell(align: right)[5], table.cell(align: right)[384], table.cell(align: left)[41-4331], table.cell(align: left)[HOUSTON SPRING BRANCH], table.cell(align: left)[TX], table.cell(align: right)[29.8042], table.cell(align: right)[-95.4914], table.cell(align: right)[75], table.cell(align: right)[13.592 km], table.cell(align: right)[426.0], table.cell(align: right)[0.021454],
)
#box(image("index_files/figure-typst/cell-38-output-1.svg"))

= Task 3, part c, implement two models that allow different GEV parameters to vary with CO₂:
<task-3-part-c-implement-two-models-that-allow-different-gev-parameters-to-vary-with-co₂>
```
nonstationary_gev_model2 (generic function with 2 methods)
```

#block[
```
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 6}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_parts :: Union{Tuple{Int64, Vararg{Any, 7}}, Tuple{Int64, Any, Any, Any, Any, Any, Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_station_header :: Union{Tuple{AbstractString, Int64}, Tuple{AbstractString, Int64, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.parse_rainfall_data :: Tuple{Vector{<:AbstractString}, Any, Int64}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.read_noaa_data :: Tuple{String}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.test_read_noaa_data :: Tuple{}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.calc_distance :: NTuple{4, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.weibull_plotting_positions :: Tuple{Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.find_nearest_stations :: Union{Tuple{Any, Any}, Tuple{Any, Any, Int64}}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.add_return_level_curve! :: Tuple{Any, Any, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.ReturnLevelPrior :: Union{}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.posterior_mean_curve! :: Tuple{Any, Vector{<:Distributions.Distribution}, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.posterior_bands! :: Tuple{Any, Vector{<:Distributions.Distribution}, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
┌ Warning: Replacing docs for `Main.Notebook.traceplot! :: Tuple{Any, Any, Any}` in module `Main.Notebook`
└ @ Base.Docs docs\Docs.jl:243
   Resolving package versions...
  No Changes to `D:\FALL 2025\CEVE 543\assignment\prblmset1\Project.toml`
  No Changes to `D:\FALL 2025\CEVE 543\assignment\prblmset1\Manifest.toml`
   Resolving package versions...
  No Changes to `D:\FALL 2025\CEVE 543\assignment\prblmset1\Project.toml`
  No Changes to `D:\FALL 2025\CEVE 543\assignment\prblmset1\Manifest.toml`
[ Info: Loaded cached samples from D:\FALL 2025\CEVE 543\assignment\prblmset1\nonstat_Location_trend.nc
=== Diagnostics for Location trend ===
[ Info: Loaded cached samples from D:\FALL 2025\CEVE 543\assignment\prblmset1\nonstat_Location_+_Scale_trends.nc
=== Diagnostics for Location + Scale trends ===
```

]
#table(
  columns: 9,
  align: (left,right,right,left,right,right,right,right,right,),
  table.header(table.cell(align: left)[], table.cell(align: right)[mean], table.cell(align: right)[std], table.cell(align: left)[eti89], table.cell(align: right)[ess\_tail], table.cell(align: right)[ess\_bulk], table.cell(align: right)[rhat], table.cell(align: right)[mcse\_mean], table.cell(align: right)[mcse\_std],),
  table.hline(),
  table.cell(align: left)[β\_μ], table.cell(align: right)[0.212], table.cell(align: right)[0.463], table.cell(align: left)[-0.535 .. 0.951], table.cell(align: right)[11087], table.cell(align: right)[12180], table.cell(align: right)[1.00], table.cell(align: right)[0.0042], table.cell(align: right)[0.0034],
  table.cell(align: left)[ξ], table.cell(align: right)[0.1559], table.cell(align: right)[0.0543], table.cell(align: left)[0.0712 .. 0.245], table.cell(align: right)[9900], table.cell(align: right)[12376], table.cell(align: right)[1.00], table.cell(align: right)[0.00049], table.cell(align: right)[0.00044],
  table.cell(align: left)[α\_μ], table.cell(align: right)[3.343], table.cell(align: right)[0.141], table.cell(align: left)[3.12 .. 3.57], table.cell(align: right)[10719], table.cell(align: right)[10861], table.cell(align: right)[1.00], table.cell(align: right)[0.0013], table.cell(align: right)[0.0011],
  table.cell(align: left)[log\_σ], table.cell(align: right)[0.193], table.cell(align: right)[0.081], table.cell(align: left)[0.0661 .. 0.324], table.cell(align: right)[9961], table.cell(align: right)[11611], table.cell(align: right)[1.00], table.cell(align: right)[0.00075], table.cell(align: right)[0.00064],
)
#block[
#table(
  columns: 9,
  align: (left,right,right,left,right,right,right,right,right,),
  table.header(table.cell(align: left)[], table.cell(align: right)[mean], table.cell(align: right)[std], table.cell(align: left)[eti89], table.cell(align: right)[ess\_tail], table.cell(align: right)[ess\_bulk], table.cell(align: right)[rhat], table.cell(align: right)[mcse\_mean], table.cell(align: right)[mcse\_std],),
  table.hline(),
  table.cell(align: left)[β\_μ], table.cell(align: right)[0.234], table.cell(align: right)[0.465], table.cell(align: left)[-0.520 .. 0.974], table.cell(align: right)[11060], table.cell(align: right)[14427], table.cell(align: right)[1.00], table.cell(align: right)[0.0039], table.cell(align: right)[0.0036],
  table.cell(align: left)[α\_σ], table.cell(align: right)[1.224], table.cell(align: right)[0.105], table.cell(align: left)[1.07 .. 1.40], table.cell(align: right)[10076], table.cell(align: right)[13928], table.cell(align: right)[1.00], table.cell(align: right)[0.00089], table.cell(align: right)[0.00086],
  table.cell(align: left)[α\_μ], table.cell(align: right)[3.342], table.cell(align: right)[0.143], table.cell(align: left)[3.12 .. 3.57], table.cell(align: right)[11060], table.cell(align: right)[12834], table.cell(align: right)[1.00], table.cell(align: right)[0.0013], table.cell(align: right)[0.0012],
  table.cell(align: left)[ξ], table.cell(align: right)[0.1839], table.cell(align: right)[0.0563], table.cell(align: left)[0.0969 .. 0.277], table.cell(align: right)[10798], table.cell(align: right)[15934], table.cell(align: right)[1.00], table.cell(align: right)[0.00045], table.cell(align: right)[0.00045],
  table.cell(align: left)[β\_σ], table.cell(align: right)[0.039], table.cell(align: right)[0.196], table.cell(align: left)[-0.271 .. 0.353], table.cell(align: right)[11676], table.cell(align: right)[16593], table.cell(align: right)[1.00], table.cell(align: right)[0.0015], table.cell(align: right)[0.0017],
)
]
#box(image("index_files/figure-typst/cell-41-output-1.svg"))

#box(image("index_files/figure-typst/cell-42-output-1.svg"))

```
extract_model2_gevs (generic function with 1 method)
```

```
2-element Vector{Vector{GeneralizedExtremeValue{Float64}}}:
 [Distributions.GeneralizedExtremeValue{Float64}(μ=3.6869014164063056, σ=1.1141947259628862, ξ=0.15142830444094812), Distributions.GeneralizedExtremeValue{Float64}(μ=3.6869014164063056, σ=1.1141947259628862, ξ=0.15142830444094812), Distributions.GeneralizedExtremeValue{Float64}(μ=3.6869014164063056, σ=1.1141947259628862, ξ=0.15142830444094812), Distributions.GeneralizedExtremeValue{Float64}(μ=3.791674806688632, σ=1.1635166818327418, ξ=0.13331510554657724), Distributions.GeneralizedExtremeValue{Float64}(μ=3.2381124835399286, σ=1.271828957287171, ξ=0.1859936351863539), Distributions.GeneralizedExtremeValue{Float64}(μ=3.4651900951193957, σ=1.29992727744411, ξ=0.15065605588479034), Distributions.GeneralizedExtremeValue{Float64}(μ=3.470366256816892, σ=1.4611245264132173, ξ=0.23065249188830744), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3350009729390004, σ=1.015779514529208, ξ=0.07969982578913588), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3494012458492968, σ=1.1295897047910295, ξ=0.11323750183949804), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3011589788544824, σ=1.2501091400081128, ξ=0.21906305862127412)  …  Distributions.GeneralizedExtremeValue{Float64}(μ=3.3344472016494593, σ=1.2640060844816612, ξ=0.1510835653649076), Distributions.GeneralizedExtremeValue{Float64}(μ=3.343621671541084, σ=1.1386607454660587, ξ=0.15902417660597276), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3900915851575166, σ=1.2163389886977145, ξ=0.14151424214891825), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3808957669285338, σ=1.1727517704038504, ξ=0.18782832405828637), Distributions.GeneralizedExtremeValue{Float64}(μ=3.535713176017228, σ=1.1890797280738266, ξ=0.21646353257800166), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3797461078684, σ=1.1617601061092082, ξ=0.19083205034962297), Distributions.GeneralizedExtremeValue{Float64}(μ=3.2980449416160793, σ=1.194548204983476, ξ=0.09186590109110207), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3107370784174615, σ=1.1927574820903932, ξ=0.12977598311019312), Distributions.GeneralizedExtremeValue{Float64}(μ=3.5193736699565927, σ=1.1598787676947173, ξ=0.18562771469689662), Distributions.GeneralizedExtremeValue{Float64}(μ=3.365629330802954, σ=1.2263431696605782, ξ=0.11403761588982449)]
 [Distributions.GeneralizedExtremeValue{Float64}(μ=3.243336572091818, σ=1.1459404956368897, ξ=0.16159249963806438), Distributions.GeneralizedExtremeValue{Float64}(μ=3.0111722901668685, σ=1.1474519270957115, ξ=0.1892977150014744), Distributions.GeneralizedExtremeValue{Float64}(μ=3.1746710350612473, σ=1.1490536403411973, ξ=0.23965611237474957), Distributions.GeneralizedExtremeValue{Float64}(μ=3.265442300408962, σ=1.11873872702865, ξ=0.17449488762254012), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3645000128938953, σ=1.057585142570059, ξ=0.11700341576777483), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3899951245596895, σ=1.227773363284233, ξ=0.09689528136900377), Distributions.GeneralizedExtremeValue{Float64}(μ=3.1757497809262336, σ=1.3484814315643112, ξ=0.17506232700499186), Distributions.GeneralizedExtremeValue{Float64}(μ=3.1757497809262336, σ=1.3484814315643112, ξ=0.17506232700499186), Distributions.GeneralizedExtremeValue{Float64}(μ=3.3355173344881215, σ=1.274573043773628, ξ=0.17228915827797392), Distributions.GeneralizedExtremeValue{Float64}(μ=3.4159333138571633, σ=1.1365906335129294, ξ=0.12861675579182455)  …  Distributions.GeneralizedExtremeValue{Float64}(μ=3.157039806736201, σ=1.2870633623390628, ξ=0.20860446049595638), Distributions.GeneralizedExtremeValue{Float64}(μ=3.664812948649506, σ=1.1399860237451778, ξ=0.21307250816827183), Distributions.GeneralizedExtremeValue{Float64}(μ=3.523213753972118, σ=1.2466101425448852, ξ=0.14972317625701492), Distributions.GeneralizedExtremeValue{Float64}(μ=3.610398340705969, σ=1.4378362226443488, ξ=0.16467697128436118), Distributions.GeneralizedExtremeValue{Float64}(μ=3.584897659068999, σ=1.4616112737541176, ξ=0.21699705237958178), Distributions.GeneralizedExtremeValue{Float64}(μ=3.5435580333927605, σ=1.3863278999737705, ξ=0.23827093969535168), Distributions.GeneralizedExtremeValue{Float64}(μ=3.5100893725107114, σ=1.3342406705816452, ξ=0.1857661549805957), Distributions.GeneralizedExtremeValue{Float64}(μ=3.55133290970257, σ=1.3195561524204156, ξ=0.278030481071953), Distributions.GeneralizedExtremeValue{Float64}(μ=3.4399235850089265, σ=1.1942031666378465, ξ=0.17788849321942019), Distributions.GeneralizedExtremeValue{Float64}(μ=3.1628347971389466, σ=1.0575329024352031, ξ=0.1796060280063584)]
```

== Task3, part 5 - Generate return level plots showing how extreme events change over time under your models
<task3-part-5---generate-return-level-plots-showing-how-extreme-events-change-over-time-under-your-models>
#box(image("index_files/figure-typst/cell-45-output-1.svg"))

#box(image("index_files/figure-typst/cell-46-output-1.svg"))

```
8-element Vector{Int64}:
 780
 782
 378
 377
 312
 770
 604
 387
```

```
([1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1897, 1898  …  2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017], Union{Missing, Float64}[missing missing … 3.18 missing; missing missing … 4.75 missing; … ; 12.35 missing … 5.69 9.79; 7.75 missing … 14.7 16.3])
```

```
(Union{Missing, Float64}[missing missing … 3.18 missing; missing missing … 4.75 missing; … ; 12.35 missing … 5.69 9.79; 7.75 missing … 14.7 16.3], [5.677130443658775, 5.678567225515137, 5.679933672624212, 5.681025487533585, 5.681707267004343, 5.6820139161830525, 5.68235452724258, 5.682831187903269, 5.683545753154764, 5.684701586843409  …  5.955401177628522, 5.960083523128392, 5.966407388912268, 5.970881240160727, 5.9764926082260175, 5.983274852924057, 5.988491381628566, 5.993992598890556, 6.002435396658721, 6.0082171847736525])
```

#block[
```
[ Info: Loaded cached samples from D:\FALL 2025\CEVE 543\assignment\prblmset1\regional_nonstat.nc
=== Regional Model Diagnostics ===
```

]
#table(
  columns: 9,
  align: (left,right,right,left,right,right,right,right,right,),
  table.header(table.cell(align: left)[], table.cell(align: right)[mean], table.cell(align: right)[std], table.cell(align: left)[eti89], table.cell(align: right)[ess\_tail], table.cell(align: right)[ess\_bulk], table.cell(align: right)[rhat], table.cell(align: right)[mcse\_mean], table.cell(align: right)[mcse\_std],),
  table.hline(),
  table.cell(align: left)[ξ\_region], table.cell(align: right)[0.2195], table.cell(align: right)[0.0345], table.cell(align: left)[0.166 .. 0.276], table.cell(align: right)[18462], table.cell(align: right)[26443], table.cell(align: right)[1.00], table.cell(align: right)[0.00021], table.cell(align: right)[0.00022],
  table.cell(align: left)[α\_μ\_stations\[1\]], table.cell(align: right)[3.464], table.cell(align: right)[0.179], table.cell(align: left)[3.18 .. 3.75], table.cell(align: right)[17614], table.cell(align: right)[20414], table.cell(align: right)[1.00], table.cell(align: right)[0.0013], table.cell(align: right)[0.0011],
  table.cell(align: left)[α\_μ\_stations\[2\]], table.cell(align: right)[3.601], table.cell(align: right)[0.190], table.cell(align: left)[3.30 .. 3.91], table.cell(align: right)[18736], table.cell(align: right)[22817], table.cell(align: right)[1.00], table.cell(align: right)[0.0013], table.cell(align: right)[0.0011],
  table.cell(align: left)[α\_μ\_stations\[3\]], table.cell(align: right)[3.545], table.cell(align: right)[0.180], table.cell(align: left)[3.26 .. 3.83], table.cell(align: right)[18913], table.cell(align: right)[21408], table.cell(align: right)[1.00], table.cell(align: right)[0.0012], table.cell(align: right)[0.0011],
  table.cell(align: left)[α\_μ\_stations\[4\]], table.cell(align: right)[3.580], table.cell(align: right)[0.233], table.cell(align: left)[3.22 .. 3.96], table.cell(align: right)[17554], table.cell(align: right)[22551], table.cell(align: right)[1.00], table.cell(align: right)[0.0016], table.cell(align: right)[0.0015],
  table.cell(align: left)[α\_μ\_stations\[5\]], table.cell(align: right)[2.958], table.cell(align: right)[0.193], table.cell(align: left)[2.66 .. 3.28], table.cell(align: right)[17443], table.cell(align: right)[19620], table.cell(align: right)[1.00], table.cell(align: right)[0.0014], table.cell(align: right)[0.0012],
  table.cell(align: left)[α\_μ\_stations\[6\]], table.cell(align: right)[3.688], table.cell(align: right)[0.177], table.cell(align: left)[3.41 .. 3.98], table.cell(align: right)[19133], table.cell(align: right)[22051], table.cell(align: right)[1.00], table.cell(align: right)[0.0012], table.cell(align: right)[0.0010],
  table.cell(align: left)[α\_μ\_stations\[7\]], table.cell(align: right)[3.402], table.cell(align: right)[0.151], table.cell(align: left)[3.16 .. 3.65], table.cell(align: right)[18559], table.cell(align: right)[18141], table.cell(align: right)[1.00], table.cell(align: right)[0.0011], table.cell(align: right)[0.00089],
  table.cell(align: left)[α\_μ\_stations\[8\]], table.cell(align: right)[3.785], table.cell(align: right)[0.229], table.cell(align: left)[3.43 .. 4.16], table.cell(align: right)[16507], table.cell(align: right)[23346], table.cell(align: right)[1.00], table.cell(align: right)[0.0015], table.cell(align: right)[0.0015],
  table.cell(align: left)[log\_σ\_stations\[1\]], table.cell(align: right)[0.385], table.cell(align: right)[0.097], table.cell(align: left)[0.232 .. 0.542], table.cell(align: right)[19107], table.cell(align: right)[21776], table.cell(align: right)[1.00], table.cell(align: right)[0.00066], table.cell(align: right)[0.00055],
  table.cell(align: left)[log\_σ\_stations\[2\]], table.cell(align: right)[0.187], table.cell(align: right)[0.122], table.cell(align: left)[-0.00510 .. 0.385], table.cell(align: right)[20268], table.cell(align: right)[27551], table.cell(align: right)[1.00], table.cell(align: right)[0.00074], table.cell(align: right)[0.00073],
  table.cell(align: left)[log\_σ\_stations\[3\]], table.cell(align: right)[0.278], table.cell(align: right)[0.110], table.cell(align: left)[0.104 .. 0.456], table.cell(align: right)[18501], table.cell(align: right)[24555], table.cell(align: right)[1.00], table.cell(align: right)[0.00070], table.cell(align: right)[0.00067],
  table.cell(align: left)[log\_σ\_stations\[4\]], table.cell(align: right)[0.493], table.cell(align: right)[0.114], table.cell(align: left)[0.314 .. 0.676], table.cell(align: right)[18612], table.cell(align: right)[25428], table.cell(align: right)[1.00], table.cell(align: right)[0.00071], table.cell(align: right)[0.00069],
  table.cell(align: left)[log\_σ\_stations\[5\]], table.cell(align: right)[0.091], table.cell(align: right)[0.129], table.cell(align: left)[-0.111 .. 0.301], table.cell(align: right)[17653], table.cell(align: right)[22648], table.cell(align: right)[1.00], table.cell(align: right)[0.00086], table.cell(align: right)[0.00080],
  table.cell(align: left)[log\_σ\_stations\[6\]], table.cell(align: right)[0.310], table.cell(align: right)[0.099], table.cell(align: left)[0.154 .. 0.469], table.cell(align: right)[19183], table.cell(align: right)[27703], table.cell(align: right)[1.00], table.cell(align: right)[0.00060], table.cell(align: right)[0.00061],
  table.cell(align: left)[log\_σ\_stations\[7\]], table.cell(align: right)[0.179], table.cell(align: right)[0.083], table.cell(align: left)[0.0489 .. 0.312], table.cell(align: right)[17943], table.cell(align: right)[25101], table.cell(align: right)[1.00], table.cell(align: right)[0.00052], table.cell(align: right)[0.00054],
  table.cell(align: left)[log\_σ\_stations\[8\]], table.cell(align: right)[0.385], table.cell(align: right)[0.131], table.cell(align: left)[0.179 .. 0.596], table.cell(align: right)[18154], table.cell(align: right)[24048], table.cell(align: right)[1.00], table.cell(align: right)[0.00085], table.cell(align: right)[0.00082],
  table.cell(align: left)[β\_region], table.cell(align: right)[0.780], table.cell(align: right)[0.591], table.cell(align: left)[-0.164 .. 1.72], table.cell(align: right)[17773], table.cell(align: right)[16301], table.cell(align: right)[1.00], table.cell(align: right)[0.0046], table.cell(align: right)[0.0036],
)
#block[
```
InferenceData with groups:
  > posterior
  > sample_stats
```

]
#box(image("index_files/figure-typst/cell-51-output-1.svg"))

```
24000-element Vector{GeneralizedExtremeValue{Float64}}:
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.6336303125090375, σ=1.383674340751439, ξ=0.22064234152768586)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.632004659454368, σ=1.3978764437199858, ξ=0.2096795690969188)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.3633624258775647, σ=1.3260903928613736, ξ=0.24211210861454205)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.4776784519303305, σ=1.5669482848505178, ξ=0.20689000720868475)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.5889150103804326, σ=1.5397403203393565, ξ=0.21054913500005284)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.5942911380009486, σ=1.3370120330215278, ξ=0.2573430407909418)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.5603434744429014, σ=1.5669489547766917, ξ=0.23562572888919228)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.511831823725886, σ=1.5270058979144883, ξ=0.19377417467234206)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.3380636154984615, σ=1.3694443708393904, ξ=0.23152374773040776)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.565059806649753, σ=1.3161648865370252, ξ=0.2500931715506363)
 ⋮
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.6335322361996902, σ=1.4072365298036367, ξ=0.23979748888274596)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.5520931066478516, σ=1.45383547235274, ξ=0.22365479040836625)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.576824569470417, σ=1.445370957377166, ξ=0.19328974958264347)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.3799019965720474, σ=1.201241634974624, ξ=0.21062496320349813)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.749152775052, σ=1.5484195883652163, ξ=0.237031892306588)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.1993560229348135, σ=1.3473725376829535, ξ=0.2207084595248287)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.369640875390186, σ=1.6802111258370709, ξ=0.2256086135396791)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.604303896859855, σ=1.4770979629916237, ξ=0.23212398418287455)
 Distributions.GeneralizedExtremeValue{Float64}(μ=3.4399750184451756, σ=1.2952632485771045, ξ=0.2471979950019972)
```

#box(image("index_files/figure-typst/cell-53-output-1.svg"))

#box(image("index_files/figure-typst/cell-54-output-1.svg"))

#box(image("index_files/figure-typst/cell-55-output-1.svg"))

#box(image("index_files/figure-typst/cell-56-output-1.svg"))

]
, 
title: 
[
Note
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
]
, 
title: 
[
Choosing Your Station- Task 1, part b, Extract annual maximum daily precipitation from station data and visualize
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
]
, 
title: 
[
Data Setup and Station Selection
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]




