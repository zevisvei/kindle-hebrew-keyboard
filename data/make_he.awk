# make_he.awk -- build a Hebrew (SI-1452) keymap on-device from the Kindle's
# OWN en_US keymap. Pure busybox-awk: no python/gawk/lua needed.
# Surgical: copies every layer verbatim, rewrites ONLY the type-16 base letter
# layer (even-spaced 8/10/9 Hebrew rows) + 3 top-level flags. Resolution-agnostic.
# The !!shift / !!back keys are preserved byte-for-byte (keep their width/press img).
# Usage: gunzip -c en_US-<res>.keymap.gz | awk -f make_he.awk - - > he-<res>.keymap
#   (the input is passed TWICE; pass1 measures geometry, pass2 emits)

function qval(s,  n,a){ n=split(s,a,"\""); return a[4] }          # 4th quote field = string value
function nval(s,  t){ t=s; sub(/^[^:]*:[ ]*/,"",t); gsub(/[^0-9-].*/,"",t); return t+0 }
function rnd(v){ return (v>=0)? int(v+0.5) : -int(-v+0.5) }
function xpos(n,left,right,w,i){ if(n<=1) return left; return rnd(left + i*((right-w-left)/(n-1))) }
function key(y,x,v,  pad,pad2){
    pad="                "; pad2="                    "       # 16 / 20 spaces
    printf "%s{\n%s\"label\": \"%s\",\n%s\"value\": \"%s\",\n%s\"x\": %d,\n%s\"y\": %d\n%s},\n",
           pad, pad2,v, pad2,v, pad2,x, pad2,y, pad
}
function emit_keys(  i,n){
    n=8;  for(i=0;i<n;i++) key(y_top,  xpos(n,leftf,rightf,W,i), TOP[i+1])
    n=10; for(i=0;i<n;i++) key(y_home, xpos(n,leftf,rightf,W,i), HOME[i+1])
    n=9;  for(i=0;i<n;i++) key(y_bot,  xpos(n,shiftx+W,backx,W,i), BOT[i+1])
    printf "%s", SHIFTRAW          # verbatim, already ends with "},"
    printf "%s", BACKRAW           # verbatim, already ends with "}" (last key, no comma)
}
function compute(  i,ya,yb,yc){
    ya=1e9; yc=-1
    for(i=1;i<=N;i++){ if(Y[i]<ya)ya=Y[i]; if(Y[i]>yc)yc=Y[i] }
    yb=yc
    for(i=1;i<=N;i++){ if(Y[i]>ya && Y[i]<yb) yb=Y[i] }
    y_top=ya; y_home=yb; y_bot=yc
    leftf=1e9; rightf=-1
    for(i=1;i<=N;i++){ if(X[i]<leftf)leftf=X[i]; if(X[i]>rightf)rightf=X[i] }
    rightf=rightf+W
}

BEGIN{
    split("\xd7\xa7 \xd7\xa8 \xd7\x90 \xd7\x98 \xd7\x95 \xd7\x9f \xd7\x9d \xd7\xa4", TOP,  " ")
    split("\xd7\xa9 \xd7\x93 \xd7\x92 \xd7\x9b \xd7\xa2 \xd7\x99 \xd7\x97 \xd7\x9c \xd7\x9a \xd7\xa3", HOME, " ")
    split("\xd7\x96 \xd7\xa1 \xd7\x91 \xd7\x94 \xd7\xa0 \xd7\x9e \xd7\xa6 \xd7\xaa \xd7\xa5", BOT, " ")
    W=56
}

# ---- pass 1: first file copy -> measure ----
NR==FNR{
    if($0 ~ /"type":[ ]*16,/){ in16=1 }
    if(in16 && !inkeys && $0 ~ /"width":/){ W=nval($0) }      # LAYER width only (before keys)
    if(in16 && $0 ~ /"keys":[ ]*\[/){ inkeys=1; next }
    if(in16 && inkeys){
        if($0 ~ /\]/){ inkeys=0; in16=0; next }
        buf=buf $0 "\n"
        if($0 ~ /"value":/){ curv=qval($0) }
        if($0 ~ /"x":/){ curx=nval($0) }
        if($0 ~ /"y":/){ cury=nval($0) }
        if($0 ~ /\}/){
            if(curv=="!!shift"){ SHIFTRAW=buf; shiftx=curx }
            else if(curv=="!!back"){ BACKRAW=buf; backx=curx }
            else { N++; V[N]=curv; X[N]=curx; Y[N]=cury }
            buf=""; curv=""; curx=""; cury=""
        }
    }
    next
}

# ---- pass 2: second file copy -> emit ----
!computed{ compute(); computed=1 }
$0 ~ /"keyboard_language"/{
    print "    \"keyboard_language\": \"he\","
    print "    \"ui_direction\": 1,"
    print "    \"keyboard_supports_caps\": false,"
    next
}
$0 ~ /"type":[ ]*16,/{ p16=1 }
p16 && $0 ~ /"keys":[ ]*\[/{ print; emit_keys(); pinkeys=1; next }
p16 && pinkeys{
    if($0 ~ /\]/){ print; pinkeys=0; p16=0; next }
    next
}
{ print }
