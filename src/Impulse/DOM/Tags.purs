module Impulse.DOM.Tags where

import Prelude (unit, Unit, (<#>))
import Impulse.DOM (DOM, ElRes, createElement, innerRes)
import Impulse.DOM.Attrs (Attrs)

{-
"a","abbr","acronym","address","applet","area","article","aside","audio","b","base","basefont","bdo",
"big","blockquote","body","br","button","canvas","caption","center","cite","code","col","colgroup",
"datalist","dd","del","dfn","div","dl","dt","em","embed","fieldset","figcaption","figure","font",
"footer","form","frame","frameset","head","header","h1 to &lt;h6&gt;","hr","html","i","iframe","img",
"input","ins","kbd","label","legend","li","link","main","map","mark","meta","meter","nav","noscript",
"object","ol","optgroup","option","p","param","pre","progress","q","s","samp","script","section",
"select","small","source","span","strike","strong","style","sub","sup","table","tbody","td",
"textarea","tfoot","th","thead","time","title","tr","u","ul","var","video","wbr"
-} -- macro bait

a :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
a attrs inner = createElement "a" attrs inner

a_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
a_ attrs inner = createElement "a" attrs inner <#> innerRes

abbr :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
abbr attrs inner = createElement "abbr" attrs inner

abbr_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
abbr_ attrs inner = createElement "abbr" attrs inner <#> innerRes

acronym :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
acronym attrs inner = createElement "acronym" attrs inner

acronym_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
acronym_ attrs inner = createElement "acronym" attrs inner <#> innerRes

address :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
address attrs inner = createElement "address" attrs inner

address_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
address_ attrs inner = createElement "address" attrs inner <#> innerRes

applet :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
applet attrs inner = createElement "applet" attrs inner

applet_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
applet_ attrs inner = createElement "applet" attrs inner <#> innerRes

area :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
area attrs inner = createElement "area" attrs inner

area_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
area_ attrs inner = createElement "area" attrs inner <#> innerRes

article :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
article attrs inner = createElement "article" attrs inner

article_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
article_ attrs inner = createElement "article" attrs inner <#> innerRes

aside :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
aside attrs inner = createElement "aside" attrs inner

aside_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
aside_ attrs inner = createElement "aside" attrs inner <#> innerRes

audio :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
audio attrs inner = createElement "audio" attrs inner

audio_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
audio_ attrs inner = createElement "audio" attrs inner <#> innerRes

b :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
b attrs inner = createElement "b" attrs inner

b_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
b_ attrs inner = createElement "b" attrs inner <#> innerRes

base :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
base attrs inner = createElement "base" attrs inner

base_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
base_ attrs inner = createElement "base" attrs inner <#> innerRes

basefont :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
basefont attrs inner = createElement "basefont" attrs inner

basefont_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
basefont_ attrs inner = createElement "basefont" attrs inner <#> innerRes

bdo :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
bdo attrs inner = createElement "bdo" attrs inner

bdo_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
bdo_ attrs inner = createElement "bdo" attrs inner <#> innerRes

big :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
big attrs inner = createElement "big" attrs inner

big_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
big_ attrs inner = createElement "big" attrs inner <#> innerRes

blockquote :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
blockquote attrs inner = createElement "blockquote" attrs inner

blockquote_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
blockquote_ attrs inner = createElement "blockquote" attrs inner <#> innerRes

body :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
body attrs inner = createElement "body" attrs inner

body_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
body_ attrs inner = createElement "body" attrs inner <#> innerRes

br :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
br attrs inner = createElement "br" attrs inner

br_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
br_ attrs inner = createElement "br" attrs inner <#> innerRes

button :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
button attrs inner = createElement "button" attrs inner

button_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
button_ attrs inner = createElement "button" attrs inner <#> innerRes

canvas :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
canvas attrs inner = createElement "canvas" attrs inner

canvas_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
canvas_ attrs inner = createElement "canvas" attrs inner <#> innerRes

caption :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
caption attrs inner = createElement "caption" attrs inner

caption_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
caption_ attrs inner = createElement "caption" attrs inner <#> innerRes

center :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
center attrs inner = createElement "center" attrs inner

center_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
center_ attrs inner = createElement "center" attrs inner <#> innerRes

cite :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
cite attrs inner = createElement "cite" attrs inner

cite_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
cite_ attrs inner = createElement "cite" attrs inner <#> innerRes

code :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
code attrs inner = createElement "code" attrs inner

code_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
code_ attrs inner = createElement "code" attrs inner <#> innerRes

col :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
col attrs inner = createElement "col" attrs inner

col_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
col_ attrs inner = createElement "col" attrs inner <#> innerRes

colgroup :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
colgroup attrs inner = createElement "colgroup" attrs inner

colgroup_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
colgroup_ attrs inner = createElement "colgroup" attrs inner <#> innerRes

datalist :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
datalist attrs inner = createElement "datalist" attrs inner

datalist_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
datalist_ attrs inner = createElement "datalist" attrs inner <#> innerRes

dd :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
dd attrs inner = createElement "dd" attrs inner

dd_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
dd_ attrs inner = createElement "dd" attrs inner <#> innerRes

del :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
del attrs inner = createElement "del" attrs inner

del_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
del_ attrs inner = createElement "del" attrs inner <#> innerRes

dfn :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
dfn attrs inner = createElement "dfn" attrs inner

dfn_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
dfn_ attrs inner = createElement "dfn" attrs inner <#> innerRes

div :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
div attrs inner = createElement "div" attrs inner

div_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
div_ attrs inner = createElement "div" attrs inner <#> innerRes

dl :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
dl attrs inner = createElement "dl" attrs inner

dl_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
dl_ attrs inner = createElement "dl" attrs inner <#> innerRes

dt :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
dt attrs inner = createElement "dt" attrs inner

dt_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
dt_ attrs inner = createElement "dt" attrs inner <#> innerRes

em :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
em attrs inner = createElement "em" attrs inner

em_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
em_ attrs inner = createElement "em" attrs inner <#> innerRes

embed :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
embed attrs inner = createElement "embed" attrs inner

embed_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
embed_ attrs inner = createElement "embed" attrs inner <#> innerRes

fieldset :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
fieldset attrs inner = createElement "fieldset" attrs inner

fieldset_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
fieldset_ attrs inner = createElement "fieldset" attrs inner <#> innerRes

figcaption :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
figcaption attrs inner = createElement "figcaption" attrs inner

figcaption_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
figcaption_ attrs inner = createElement "figcaption" attrs inner <#> innerRes

figure :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
figure attrs inner = createElement "figure" attrs inner

figure_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
figure_ attrs inner = createElement "figure" attrs inner <#> innerRes

font :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
font attrs inner = createElement "font" attrs inner

font_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
font_ attrs inner = createElement "font" attrs inner <#> innerRes

footer :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
footer attrs inner = createElement "footer" attrs inner

footer_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
footer_ attrs inner = createElement "footer" attrs inner <#> innerRes

form :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
form attrs inner = createElement "form" attrs inner

form_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
form_ attrs inner = createElement "form" attrs inner <#> innerRes

frame :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
frame attrs inner = createElement "frame" attrs inner

frame_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
frame_ attrs inner = createElement "frame" attrs inner <#> innerRes

frameset :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
frameset attrs inner = createElement "frameset" attrs inner

frameset_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
frameset_ attrs inner = createElement "frameset" attrs inner <#> innerRes

head :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
head attrs inner = createElement "head" attrs inner

head_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
head_ attrs inner = createElement "head" attrs inner <#> innerRes

header :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
header attrs inner = createElement "header" attrs inner

header_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
header_ attrs inner = createElement "header" attrs inner <#> innerRes

h1 :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
h1 attrs inner = createElement "h1" attrs inner

h1_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
h1_ attrs inner = createElement "h1" attrs inner <#> innerRes

h2 :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
h2 attrs inner = createElement "h2" attrs inner

h2_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
h2_ attrs inner = createElement "h2" attrs inner <#> innerRes

h3 :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
h3 attrs inner = createElement "h3" attrs inner

h3_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
h3_ attrs inner = createElement "h3" attrs inner <#> innerRes

h4 :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
h4 attrs inner = createElement "h4" attrs inner

h4_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
h4_ attrs inner = createElement "h4" attrs inner <#> innerRes

h5 :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
h5 attrs inner = createElement "h5" attrs inner

h5_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
h5_ attrs inner = createElement "h5" attrs inner <#> innerRes

h6 :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
h6 attrs inner = createElement "h6" attrs inner

h6_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
h6_ attrs inner = createElement "h6" attrs inner <#> innerRes

hr :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
hr attrs inner = createElement "hr" attrs inner

hr_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
hr_ attrs inner = createElement "hr" attrs inner <#> innerRes

html :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
html attrs inner = createElement "html" attrs inner

html_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
html_ attrs inner = createElement "html" attrs inner <#> innerRes

i :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
i attrs inner = createElement "i" attrs inner

i_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
i_ attrs inner = createElement "i" attrs inner <#> innerRes

iframe :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
iframe attrs inner = createElement "iframe" attrs inner

iframe_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
iframe_ attrs inner = createElement "iframe" attrs inner <#> innerRes

img :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
img attrs inner = createElement "img" attrs inner

img_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
img_ attrs inner = createElement "img" attrs inner <#> innerRes

input :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
input attrs inner = createElement "input" attrs inner

input_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
input_ attrs inner = createElement "input" attrs inner <#> innerRes

ins :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
ins attrs inner = createElement "ins" attrs inner

ins_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
ins_ attrs inner = createElement "ins" attrs inner <#> innerRes

kbd :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
kbd attrs inner = createElement "kbd" attrs inner

kbd_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
kbd_ attrs inner = createElement "kbd" attrs inner <#> innerRes

label :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
label attrs inner = createElement "label" attrs inner

label_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
label_ attrs inner = createElement "label" attrs inner <#> innerRes

legend :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
legend attrs inner = createElement "legend" attrs inner

legend_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
legend_ attrs inner = createElement "legend" attrs inner <#> innerRes

li :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
li attrs inner = createElement "li" attrs inner

li_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
li_ attrs inner = createElement "li" attrs inner <#> innerRes

link :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
link attrs inner = createElement "link" attrs inner

link_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
link_ attrs inner = createElement "link" attrs inner <#> innerRes

main :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
main attrs inner = createElement "main" attrs inner

main_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
main_ attrs inner = createElement "main" attrs inner <#> innerRes

map :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
map attrs inner = createElement "map" attrs inner

map_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
map_ attrs inner = createElement "map" attrs inner <#> innerRes

mark :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
mark attrs inner = createElement "mark" attrs inner

mark_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
mark_ attrs inner = createElement "mark" attrs inner <#> innerRes

meta :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
meta attrs inner = createElement "meta" attrs inner

meta_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
meta_ attrs inner = createElement "meta" attrs inner <#> innerRes

meter :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
meter attrs inner = createElement "meter" attrs inner

meter_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
meter_ attrs inner = createElement "meter" attrs inner <#> innerRes

nav :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
nav attrs inner = createElement "nav" attrs inner

nav_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
nav_ attrs inner = createElement "nav" attrs inner <#> innerRes

noscript :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
noscript attrs inner = createElement "noscript" attrs inner

noscript_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
noscript_ attrs inner = createElement "noscript" attrs inner <#> innerRes

object :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
object attrs inner = createElement "object" attrs inner

object_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
object_ attrs inner = createElement "object" attrs inner <#> innerRes

ol :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
ol attrs inner = createElement "ol" attrs inner

ol_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
ol_ attrs inner = createElement "ol" attrs inner <#> innerRes

optgroup :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
optgroup attrs inner = createElement "optgroup" attrs inner

optgroup_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
optgroup_ attrs inner = createElement "optgroup" attrs inner <#> innerRes

option :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
option attrs inner = createElement "option" attrs inner

option_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
option_ attrs inner = createElement "option" attrs inner <#> innerRes

p :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
p attrs inner = createElement "p" attrs inner

p_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
p_ attrs inner = createElement "p" attrs inner <#> innerRes

param :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
param attrs inner = createElement "param" attrs inner

param_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
param_ attrs inner = createElement "param" attrs inner <#> innerRes

pre :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
pre attrs inner = createElement "pre" attrs inner

pre_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
pre_ attrs inner = createElement "pre" attrs inner <#> innerRes

progress :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
progress attrs inner = createElement "progress" attrs inner

progress_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
progress_ attrs inner = createElement "progress" attrs inner <#> innerRes

q :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
q attrs inner = createElement "q" attrs inner

q_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
q_ attrs inner = createElement "q" attrs inner <#> innerRes

s :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
s attrs inner = createElement "s" attrs inner

s_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
s_ attrs inner = createElement "s" attrs inner <#> innerRes

samp :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
samp attrs inner = createElement "samp" attrs inner

samp_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
samp_ attrs inner = createElement "samp" attrs inner <#> innerRes

script :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
script attrs inner = createElement "script" attrs inner

script_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
script_ attrs inner = createElement "script" attrs inner <#> innerRes

section :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
section attrs inner = createElement "section" attrs inner

section_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
section_ attrs inner = createElement "section" attrs inner <#> innerRes

select :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
select attrs inner = createElement "select" attrs inner

select_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
select_ attrs inner = createElement "select" attrs inner <#> innerRes

small :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
small attrs inner = createElement "small" attrs inner

small_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
small_ attrs inner = createElement "small" attrs inner <#> innerRes

source :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
source attrs inner = createElement "source" attrs inner

source_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
source_ attrs inner = createElement "source" attrs inner <#> innerRes

span :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
span attrs inner = createElement "span" attrs inner

span_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
span_ attrs inner = createElement "span" attrs inner <#> innerRes

strike :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
strike attrs inner = createElement "strike" attrs inner

strike_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
strike_ attrs inner = createElement "strike" attrs inner <#> innerRes

strong :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
strong attrs inner = createElement "strong" attrs inner

strong_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
strong_ attrs inner = createElement "strong" attrs inner <#> innerRes

d_style :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
d_style attrs inner = createElement "style" attrs inner

d_style_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
d_style_ attrs inner = createElement "style" attrs inner <#> innerRes

sub :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
sub attrs inner = createElement "sub" attrs inner

sub_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
sub_ attrs inner = createElement "sub" attrs inner <#> innerRes

sup :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
sup attrs inner = createElement "sup" attrs inner

sup_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
sup_ attrs inner = createElement "sup" attrs inner <#> innerRes

table :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
table attrs inner = createElement "table" attrs inner

table_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
table_ attrs inner = createElement "table" attrs inner <#> innerRes

tbody :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
tbody attrs inner = createElement "tbody" attrs inner

tbody_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
tbody_ attrs inner = createElement "tbody" attrs inner <#> innerRes

td :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
td attrs inner = createElement "td" attrs inner

td_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
td_ attrs inner = createElement "td" attrs inner <#> innerRes

textarea :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
textarea attrs inner = createElement "textarea" attrs inner

textarea_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
textarea_ attrs inner = createElement "textarea" attrs inner <#> innerRes

tfoot :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
tfoot attrs inner = createElement "tfoot" attrs inner

tfoot_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
tfoot_ attrs inner = createElement "tfoot" attrs inner <#> innerRes

th :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
th attrs inner = createElement "th" attrs inner

th_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
th_ attrs inner = createElement "th" attrs inner <#> innerRes

thead :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
thead attrs inner = createElement "thead" attrs inner

thead_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
thead_ attrs inner = createElement "thead" attrs inner <#> innerRes

time :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
time attrs inner = createElement "time" attrs inner

time_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
time_ attrs inner = createElement "time" attrs inner <#> innerRes

title :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
title attrs inner = createElement "title" attrs inner

title_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
title_ attrs inner = createElement "title" attrs inner <#> innerRes

tr :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
tr attrs inner = createElement "tr" attrs inner

tr_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
tr_ attrs inner = createElement "tr" attrs inner <#> innerRes

u :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
u attrs inner = createElement "u" attrs inner

u_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
u_ attrs inner = createElement "u" attrs inner <#> innerRes

ul :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
ul attrs inner = createElement "ul" attrs inner

ul_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
ul_ attrs inner = createElement "ul" attrs inner <#> innerRes

var :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
var attrs inner = createElement "var" attrs inner

var_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
var_ attrs inner = createElement "var" attrs inner <#> innerRes

video :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
video attrs inner = createElement "video" attrs inner

video_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
video_ attrs inner = createElement "video" attrs inner <#> innerRes

wbr :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
wbr attrs inner = createElement "wbr" attrs inner

wbr_ :: forall e c a. Attrs Unit -> DOM e c a -> DOM e c a
wbr_ attrs inner = createElement "wbr" attrs inner <#> innerRes

