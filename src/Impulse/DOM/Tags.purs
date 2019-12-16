module Impulse.DOM.Tags where

import Prelude (unit, Unit, (<#>))
import Impulse.DOM.API (DOM, createElement)
import Impulse.DOM.Attrs (Attrs)
import Impulse.DOM.ImpulseEl (ImpulseEl, elRes)

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

a :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
a attrs inner = createElement "a" attrs inner

a_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
a_ attrs inner = createElement "a" attrs inner <#> elRes

abbr :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
abbr attrs inner = createElement "abbr" attrs inner

abbr_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
abbr_ attrs inner = createElement "abbr" attrs inner <#> elRes

acronym :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
acronym attrs inner = createElement "acronym" attrs inner

acronym_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
acronym_ attrs inner = createElement "acronym" attrs inner <#> elRes

address :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
address attrs inner = createElement "address" attrs inner

address_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
address_ attrs inner = createElement "address" attrs inner <#> elRes

applet :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
applet attrs inner = createElement "applet" attrs inner

applet_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
applet_ attrs inner = createElement "applet" attrs inner <#> elRes

area :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
area attrs inner = createElement "area" attrs inner

area_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
area_ attrs inner = createElement "area" attrs inner <#> elRes

article :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
article attrs inner = createElement "article" attrs inner

article_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
article_ attrs inner = createElement "article" attrs inner <#> elRes

aside :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
aside attrs inner = createElement "aside" attrs inner

aside_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
aside_ attrs inner = createElement "aside" attrs inner <#> elRes

audio :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
audio attrs inner = createElement "audio" attrs inner

audio_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
audio_ attrs inner = createElement "audio" attrs inner <#> elRes

b :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
b attrs inner = createElement "b" attrs inner

b_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
b_ attrs inner = createElement "b" attrs inner <#> elRes

base :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
base attrs inner = createElement "base" attrs inner

base_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
base_ attrs inner = createElement "base" attrs inner <#> elRes

basefont :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
basefont attrs inner = createElement "basefont" attrs inner

basefont_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
basefont_ attrs inner = createElement "basefont" attrs inner <#> elRes

bdo :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
bdo attrs inner = createElement "bdo" attrs inner

bdo_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
bdo_ attrs inner = createElement "bdo" attrs inner <#> elRes

big :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
big attrs inner = createElement "big" attrs inner

big_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
big_ attrs inner = createElement "big" attrs inner <#> elRes

blockquote :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
blockquote attrs inner = createElement "blockquote" attrs inner

blockquote_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
blockquote_ attrs inner = createElement "blockquote" attrs inner <#> elRes

body :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
body attrs inner = createElement "body" attrs inner

body_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
body_ attrs inner = createElement "body" attrs inner <#> elRes

br :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
br attrs inner = createElement "br" attrs inner

br_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
br_ attrs inner = createElement "br" attrs inner <#> elRes

button :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
button attrs inner = createElement "button" attrs inner

button_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
button_ attrs inner = createElement "button" attrs inner <#> elRes

canvas :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
canvas attrs inner = createElement "canvas" attrs inner

canvas_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
canvas_ attrs inner = createElement "canvas" attrs inner <#> elRes

caption :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
caption attrs inner = createElement "caption" attrs inner

caption_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
caption_ attrs inner = createElement "caption" attrs inner <#> elRes

center :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
center attrs inner = createElement "center" attrs inner

center_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
center_ attrs inner = createElement "center" attrs inner <#> elRes

cite :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
cite attrs inner = createElement "cite" attrs inner

cite_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
cite_ attrs inner = createElement "cite" attrs inner <#> elRes

code :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
code attrs inner = createElement "code" attrs inner

code_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
code_ attrs inner = createElement "code" attrs inner <#> elRes

col :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
col attrs inner = createElement "col" attrs inner

col_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
col_ attrs inner = createElement "col" attrs inner <#> elRes

colgroup :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
colgroup attrs inner = createElement "colgroup" attrs inner

colgroup_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
colgroup_ attrs inner = createElement "colgroup" attrs inner <#> elRes

datalist :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
datalist attrs inner = createElement "datalist" attrs inner

datalist_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
datalist_ attrs inner = createElement "datalist" attrs inner <#> elRes

dd :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
dd attrs inner = createElement "dd" attrs inner

dd_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
dd_ attrs inner = createElement "dd" attrs inner <#> elRes

del :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
del attrs inner = createElement "del" attrs inner

del_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
del_ attrs inner = createElement "del" attrs inner <#> elRes

dfn :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
dfn attrs inner = createElement "dfn" attrs inner

dfn_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
dfn_ attrs inner = createElement "dfn" attrs inner <#> elRes

div :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
div attrs inner = createElement "div" attrs inner

div_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
div_ attrs inner = createElement "div" attrs inner <#> elRes

dl :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
dl attrs inner = createElement "dl" attrs inner

dl_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
dl_ attrs inner = createElement "dl" attrs inner <#> elRes

dt :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
dt attrs inner = createElement "dt" attrs inner

dt_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
dt_ attrs inner = createElement "dt" attrs inner <#> elRes

em :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
em attrs inner = createElement "em" attrs inner

em_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
em_ attrs inner = createElement "em" attrs inner <#> elRes

embed :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
embed attrs inner = createElement "embed" attrs inner

embed_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
embed_ attrs inner = createElement "embed" attrs inner <#> elRes

fieldset :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
fieldset attrs inner = createElement "fieldset" attrs inner

fieldset_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
fieldset_ attrs inner = createElement "fieldset" attrs inner <#> elRes

figcaption :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
figcaption attrs inner = createElement "figcaption" attrs inner

figcaption_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
figcaption_ attrs inner = createElement "figcaption" attrs inner <#> elRes

figure :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
figure attrs inner = createElement "figure" attrs inner

figure_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
figure_ attrs inner = createElement "figure" attrs inner <#> elRes

font :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
font attrs inner = createElement "font" attrs inner

font_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
font_ attrs inner = createElement "font" attrs inner <#> elRes

footer :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
footer attrs inner = createElement "footer" attrs inner

footer_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
footer_ attrs inner = createElement "footer" attrs inner <#> elRes

form :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
form attrs inner = createElement "form" attrs inner

form_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
form_ attrs inner = createElement "form" attrs inner <#> elRes

frame :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
frame attrs inner = createElement "frame" attrs inner

frame_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
frame_ attrs inner = createElement "frame" attrs inner <#> elRes

frameset :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
frameset attrs inner = createElement "frameset" attrs inner

frameset_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
frameset_ attrs inner = createElement "frameset" attrs inner <#> elRes

head :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
head attrs inner = createElement "head" attrs inner

head_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
head_ attrs inner = createElement "head" attrs inner <#> elRes

header :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
header attrs inner = createElement "header" attrs inner

header_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
header_ attrs inner = createElement "header" attrs inner <#> elRes

h1 :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
h1 attrs inner = createElement "h1" attrs inner

h1_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
h1_ attrs inner = createElement "h1" attrs inner <#> elRes

h2 :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
h2 attrs inner = createElement "h2" attrs inner

h2_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
h2_ attrs inner = createElement "h2" attrs inner <#> elRes

h3 :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
h3 attrs inner = createElement "h3" attrs inner

h3_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
h3_ attrs inner = createElement "h3" attrs inner <#> elRes

h4 :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
h4 attrs inner = createElement "h4" attrs inner

h4_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
h4_ attrs inner = createElement "h4" attrs inner <#> elRes

h5 :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
h5 attrs inner = createElement "h5" attrs inner

h5_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
h5_ attrs inner = createElement "h5" attrs inner <#> elRes

h6 :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
h6 attrs inner = createElement "h6" attrs inner

h6_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
h6_ attrs inner = createElement "h6" attrs inner <#> elRes

hr :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
hr attrs inner = createElement "hr" attrs inner

hr_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
hr_ attrs inner = createElement "hr" attrs inner <#> elRes

html :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
html attrs inner = createElement "html" attrs inner

html_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
html_ attrs inner = createElement "html" attrs inner <#> elRes

i :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
i attrs inner = createElement "i" attrs inner

i_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
i_ attrs inner = createElement "i" attrs inner <#> elRes

iframe :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
iframe attrs inner = createElement "iframe" attrs inner

iframe_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
iframe_ attrs inner = createElement "iframe" attrs inner <#> elRes

img :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
img attrs inner = createElement "img" attrs inner

img_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
img_ attrs inner = createElement "img" attrs inner <#> elRes

input :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
input attrs inner = createElement "input" attrs inner

input_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
input_ attrs inner = createElement "input" attrs inner <#> elRes

ins :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
ins attrs inner = createElement "ins" attrs inner

ins_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
ins_ attrs inner = createElement "ins" attrs inner <#> elRes

kbd :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
kbd attrs inner = createElement "kbd" attrs inner

kbd_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
kbd_ attrs inner = createElement "kbd" attrs inner <#> elRes

label :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
label attrs inner = createElement "label" attrs inner

label_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
label_ attrs inner = createElement "label" attrs inner <#> elRes

legend :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
legend attrs inner = createElement "legend" attrs inner

legend_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
legend_ attrs inner = createElement "legend" attrs inner <#> elRes

li :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
li attrs inner = createElement "li" attrs inner

li_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
li_ attrs inner = createElement "li" attrs inner <#> elRes

link :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
link attrs inner = createElement "link" attrs inner

link_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
link_ attrs inner = createElement "link" attrs inner <#> elRes

main :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
main attrs inner = createElement "main" attrs inner

main_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
main_ attrs inner = createElement "main" attrs inner <#> elRes

map :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
map attrs inner = createElement "map" attrs inner

map_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
map_ attrs inner = createElement "map" attrs inner <#> elRes

mark :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
mark attrs inner = createElement "mark" attrs inner

mark_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
mark_ attrs inner = createElement "mark" attrs inner <#> elRes

meta :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
meta attrs inner = createElement "meta" attrs inner

meta_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
meta_ attrs inner = createElement "meta" attrs inner <#> elRes

meter :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
meter attrs inner = createElement "meter" attrs inner

meter_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
meter_ attrs inner = createElement "meter" attrs inner <#> elRes

nav :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
nav attrs inner = createElement "nav" attrs inner

nav_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
nav_ attrs inner = createElement "nav" attrs inner <#> elRes

noscript :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
noscript attrs inner = createElement "noscript" attrs inner

noscript_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
noscript_ attrs inner = createElement "noscript" attrs inner <#> elRes

object :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
object attrs inner = createElement "object" attrs inner

object_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
object_ attrs inner = createElement "object" attrs inner <#> elRes

ol :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
ol attrs inner = createElement "ol" attrs inner

ol_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
ol_ attrs inner = createElement "ol" attrs inner <#> elRes

optgroup :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
optgroup attrs inner = createElement "optgroup" attrs inner

optgroup_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
optgroup_ attrs inner = createElement "optgroup" attrs inner <#> elRes

option :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
option attrs inner = createElement "option" attrs inner

option_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
option_ attrs inner = createElement "option" attrs inner <#> elRes

p :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
p attrs inner = createElement "p" attrs inner

p_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
p_ attrs inner = createElement "p" attrs inner <#> elRes

param :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
param attrs inner = createElement "param" attrs inner

param_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
param_ attrs inner = createElement "param" attrs inner <#> elRes

pre :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
pre attrs inner = createElement "pre" attrs inner

pre_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
pre_ attrs inner = createElement "pre" attrs inner <#> elRes

progress :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
progress attrs inner = createElement "progress" attrs inner

progress_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
progress_ attrs inner = createElement "progress" attrs inner <#> elRes

q :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
q attrs inner = createElement "q" attrs inner

q_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
q_ attrs inner = createElement "q" attrs inner <#> elRes

s :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
s attrs inner = createElement "s" attrs inner

s_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
s_ attrs inner = createElement "s" attrs inner <#> elRes

samp :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
samp attrs inner = createElement "samp" attrs inner

samp_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
samp_ attrs inner = createElement "samp" attrs inner <#> elRes

script :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
script attrs inner = createElement "script" attrs inner

script_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
script_ attrs inner = createElement "script" attrs inner <#> elRes

section :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
section attrs inner = createElement "section" attrs inner

section_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
section_ attrs inner = createElement "section" attrs inner <#> elRes

select :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
select attrs inner = createElement "select" attrs inner

select_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
select_ attrs inner = createElement "select" attrs inner <#> elRes

small :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
small attrs inner = createElement "small" attrs inner

small_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
small_ attrs inner = createElement "small" attrs inner <#> elRes

source :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
source attrs inner = createElement "source" attrs inner

source_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
source_ attrs inner = createElement "source" attrs inner <#> elRes

span :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
span attrs inner = createElement "span" attrs inner

span_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
span_ attrs inner = createElement "span" attrs inner <#> elRes

strike :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
strike attrs inner = createElement "strike" attrs inner

strike_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
strike_ attrs inner = createElement "strike" attrs inner <#> elRes

strong :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
strong attrs inner = createElement "strong" attrs inner

strong_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
strong_ attrs inner = createElement "strong" attrs inner <#> elRes

d_style :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
d_style attrs inner = createElement "style" attrs inner

d_style_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
d_style_ attrs inner = createElement "style" attrs inner <#> elRes

sub :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
sub attrs inner = createElement "sub" attrs inner

sub_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
sub_ attrs inner = createElement "sub" attrs inner <#> elRes

sup :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
sup attrs inner = createElement "sup" attrs inner

sup_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
sup_ attrs inner = createElement "sup" attrs inner <#> elRes

table :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
table attrs inner = createElement "table" attrs inner

table_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
table_ attrs inner = createElement "table" attrs inner <#> elRes

tbody :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
tbody attrs inner = createElement "tbody" attrs inner

tbody_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
tbody_ attrs inner = createElement "tbody" attrs inner <#> elRes

td :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
td attrs inner = createElement "td" attrs inner

td_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
td_ attrs inner = createElement "td" attrs inner <#> elRes

textarea :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
textarea attrs inner = createElement "textarea" attrs inner

textarea_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
textarea_ attrs inner = createElement "textarea" attrs inner <#> elRes

tfoot :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
tfoot attrs inner = createElement "tfoot" attrs inner

tfoot_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
tfoot_ attrs inner = createElement "tfoot" attrs inner <#> elRes

th :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
th attrs inner = createElement "th" attrs inner

th_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
th_ attrs inner = createElement "th" attrs inner <#> elRes

thead :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
thead attrs inner = createElement "thead" attrs inner

thead_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
thead_ attrs inner = createElement "thead" attrs inner <#> elRes

time :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
time attrs inner = createElement "time" attrs inner

time_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
time_ attrs inner = createElement "time" attrs inner <#> elRes

title :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
title attrs inner = createElement "title" attrs inner

title_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
title_ attrs inner = createElement "title" attrs inner <#> elRes

tr :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
tr attrs inner = createElement "tr" attrs inner

tr_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
tr_ attrs inner = createElement "tr" attrs inner <#> elRes

u :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
u attrs inner = createElement "u" attrs inner

u_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
u_ attrs inner = createElement "u" attrs inner <#> elRes

ul :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
ul attrs inner = createElement "ul" attrs inner

ul_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
ul_ attrs inner = createElement "ul" attrs inner <#> elRes

var :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
var attrs inner = createElement "var" attrs inner

var_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
var_ attrs inner = createElement "var" attrs inner <#> elRes

video :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
video attrs inner = createElement "video" attrs inner

video_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
video_ attrs inner = createElement "video" attrs inner <#> elRes

wbr :: forall e c a. Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
wbr attrs inner = createElement "wbr" attrs inner

wbr_ :: forall e c a. Attrs -> DOM e c a -> DOM e c a
wbr_ attrs inner = createElement "wbr" attrs inner <#> elRes

