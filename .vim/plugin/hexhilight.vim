"gvim plugin for highlighting hex codes to help with tweaking colors
"Last Change: 2010 Jan 21
"Maintainer: Yuri Feldman <feldman.yuri1@gmail.com>
"License: WTFPL - Do What The Fuck You Want To Public License.
"Email me if you'd like.
let s:HexColored = 0
let s:HexColors = []

map <Leader><F2> :call HexHighlight()<Return>
function! HexHighlight()
    if has("gui_running")
        if s:HexColored == 0
            let hexGroup = 4
            let lineNumber = 0
            while lineNumber <= line("$")
                let currentLine = getline(lineNumber)
                let hexLineMatch = 1
                while match(currentLine, '#\x\{6}', 0, hexLineMatch) != -1
                    let hexMatch = matchstr(currentLine, '#\x\{6}', 0, hexLineMatch)
                    exe 'hi hexColor'.hexGroup.' guibg='.hexMatch.' guifg='.s:FGforBG(hexMatch)
                    exe 'let m = matchadd("hexColor'.hexGroup.'", "'.hexMatch.'", 25, '.hexGroup.')'
                    let s:HexColors += ['hexColor'.hexGroup]
                    let hexGroup += 1
                    let hexLineMatch += 1
                endwhile
                let lineNumber += 1
            endwhile
            unlet lineNumber hexGroup
            let s:HexColored = 1
            echo "Highlighting hex colors..."
        elseif s:HexColored == 1
            for hexColor in s:HexColors
                exe 'highlight clear '.hexColor
            endfor
            call clearmatches()
            let s:HexColored = 0
            echo "Unhighlighting hex colors..."
        endif
    else
        if s:HexColored == 0
            let hexGroup = 4
            let lineNumber = 0
            while lineNumber <= line("$")
                let currentLine = getline(lineNumber)
                let hexLineMatch = 1
                while match(currentLine, '#\x\{6}', 0, hexLineMatch) != -1
                    let hexMatch = matchstr(currentLine, '#\x\{6}', 0, hexLineMatch)
                    exe 'hi hexColor'.hexGroup.' guibg='.s:Rgb2xterm(hexMatch).' guifg=#'.s:Rgb2xterm(s:FGforBG(hexMatch))
                    exe 'let m = matchadd("hexColor'.hexGroup.'", "'.hexMatch.'", 25, '.hexGroup.')'
                    let s:HexColors += ['hexColor'.hexGroup]
                    let hexGroup += 1
                    let hexLineMatch += 1
                endwhile
                let lineNumber += 1
            endwhile
            unlet lineNumber hexGroup
            let s:HexColored = 1
            echo "Highlighting hex colors..."
        elseif s:HexColored == 1
            for hexColor in s:HexColors
                exe 'highlight clear '.hexColor
            endfor
            call clearmatches()
            let s:HexColored = 0
            echo "Unhighlighting hex colors..."
        endif
    endif
endfunction





function! s:StrLen(str)
  return strlen(substitute(a:str, '.', 'x', 'g'))
endfunction

function! s:FGforBG(bg)
  " takes a 6hex color code and returns a matching color that is visible
  let pure = substitute(a:bg,'^#','','')
  let r = eval('0x'.pure[0].pure[1])
  let g = eval('0x'.pure[2].pure[3])
  let b = eval('0x'.pure[4].pure[5])
  if r*30 + g*59 + b*11 > 12000
    return '#000000'
  else
    return '#ffffff'
  end
endfunction


"" the 6 value iterations in the xterm color cube
let s:valuerange = [ 0x00, 0x5F, 0x87, 0xAF, 0xD7, 0xFF ]
"
"" 16 basic colors
let s:basic16 = [ [ 0x00, 0x00, 0x00 ], [ 0xCD, 0x00, 0x00 ], [ 0x00, 0xCD, 0x00 ], [ 0xCD, 0xCD, 0x00 ], [ 0x00, 0x00, 0xEE ], [ 0xCD, 0x00, 0xCD ], [ 0x00, 0xCD, 0xCD ], [ 0xE5, 0xE5, 0xE5 ], [ 0x7F, 0x7F, 0x7F ], [ 0xFF, 0x00, 0x00 ], [ 0x00, 0xFF, 0x00 ], [ 0xFF, 0xFF, 0x00 ], [ 0x5C, 0x5C, 0xFF ], [ 0xFF, 0x00, 0xFF ], [ 0x00, 0xFF, 0xFF ], [ 0xFF, 0xFF, 0xFF ] ]
:
function! s:Xterm2rgb(color)
  " 16 basic colors
  let r=0
  let g=0
  let b=0
  if a:color<16
    let r = s:basic16[a:color][0]
    let g = s:basic16[a:color][1]
    let b = s:basic16[a:color][2]
  endif

  " color cube color
  if a:color>=16 && a:color<=232
    let color=a:color-16
    let r = s:valuerange[(color/36)%6]
    let g = s:valuerange[(color/6)%6]
    let b = s:valuerange[color%6]
  endif

  " gray tone
  if a:color>=233 && a:color<=253
    let r=8+(a:color-232)*0x0a
    let g=r
    let b=r
  endif
  let rgb=[r,g,b]
  return rgb
endfunction

function! s:pow(x, n)
  let x = a:x
  for i in range(a:n-1)
    let x = x*a:x
  return x
endfunction

let s:colortable=[]
for c in range(0, 254)
  let color = s:Xterm2rgb(c)
  call add(s:colortable, color)
endfor

" selects the nearest xterm color for a rgb value like #FF0000
function! s:Rgb2xterm(color)
  let best_match=0
  let smallest_distance = 10000000000
  let r = eval('0x'.a:color[1].a:color[2])
  let g = eval('0x'.a:color[3].a:color[4])
  let b = eval('0x'.a:color[5].a:color[6])
  for c in range(0,254)
    let d = s:pow(s:colortable[c][0]-r,2) + s:pow(s:colortable[c][1]-g,2) + s:pow(s:colortable[c][2]-b,2)
    if d<smallest_distance
      let smallest_distance = d
      let best_match = c
    endif
  endfor
  return best_match
endfunction

function! s:SetNamedColor(clr,name)
  let group = 'cssColor'.substitute(a:clr,'^#','','')
  exe 'syn keyword '.group.' '.a:name.' contained'
  exe 'syn cluster cssColors add='.group
  if has('gui_running')
    exe 'hi '.group.' guifg='.s:FGforBG(a:clr)
    exe 'hi '.group.' guibg='.a:clr
  elseif &t_Co == 256
    exe 'hi '.group.' ctermfg='.s:Rgb2xterm(s:FGforBG(a:clr))
    exe 'hi '.group.' ctermbg='.s:Rgb2xterm(a:clr)
  endif
  return 23
endfunction

" shamelessly stolen from ConvertBase.vim
" http://www.vim.org/scripts/script.php?script_id=54
function! s:ConvertToBase(int, base)
  if (a:base < 2 || a:base > 36)
    echohl ErrorMsg
    echo "Bad base - must be between 2 and 36."
    echohl None
    return ''
  endif

  if (a:int == 0)
    return 0
  endif

  let out=''

  let isnegative = 0
  let int=a:int
  if (int < 0)
    let isnegative = 1
    let int = - int
  endif

  while (int != 0)
    let out = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"[(int % a:base)] . out
    let int = int / a:base
  endwhile

  if isnegative
    let out = '-' . out
  endif

  return out
endfunction

" Convert 80% -> 204, 100% -> 255, etc.
" This piece of code was ported from lisp.
" http://julien.danjou.info/rainbow-mode.html
fun! s:RGBRelativeToAbsolute(value)
  let string_length = s:StrLen(a:value)-1
  if strpart(a:value, string_length, 1) == '%'
    let hex_value = s:ConvertToBase(  255*strpart(a:value, 0, string_length)/100, 16 )
    if len(hex_value) == 1
      return "0".hex_value
    endif
    return hex_value
  else
    let hex_value = s:ConvertToBase( a:value, 16 )
    if len( hex_value ) == 1
      return "0".hex_value
    else
      return hex_value
    endif
  endif
endf

function! s:PreviewCSSColorInLine(where)
  " TODO use cssColor matchdata
  let n = 1
  let foundcolor = matchstr( getline(a:where), '#[0-9A-Fa-f]\{3,6\}\>' )
  while foundcolor != ''
    if foundcolor =~ '#\x\{6}$'
      let color = foundcolor
    elseif foundcolor =~ '#\x\{3}$'
      let color = substitute(foundcolor, '\(\x\)\(\x\)\(\x\)', '\1\1\2\2\3\3', '')
    else
      let color = ''
    endif

    if color != ''
      call s:SetMatcher(color,foundcolor)
    endif

    let n+=1
    let foundcolor = matchstr( getline(a:where), '#[0-9A-Fa-f]\{3,6}', 0, n )
  endwhile


  let n = 1
  let foundcolorlist = matchlist( getline(a:where), 'rgb[a]\=(\(\d\{1,3}\s*%\=\),\s*\(\d\{1,3}\s*%\=\),\s*\(\d\{1,3}\s*%\=\).\{-})', 0, n )
  while len(foundcolorlist) != 0
      let foundcolorlist[1] = s:RGBRelativeToAbsolute( foundcolorlist[1] )
      let foundcolorlist[2] = s:RGBRelativeToAbsolute( foundcolorlist[2] )
      let foundcolorlist[3] = s:RGBRelativeToAbsolute( foundcolorlist[3] )

      let color = "#".join( foundcolorlist[1:3], "" )

      call s:SetMatcher( color, foundcolorlist[0] )

      let n+=1
      let foundcolorlist = matchlist( getline(a:where), 'rgb[a]\=(\(\d\{1,3}\s*%\=\),\s*\(\d\{1,3}\s*%\=\),\s*\(\d\{1,3}\s*%\=\).\{-})', 0, n )
  endw
  return 0
endfunction

if has("gui_running") || &t_Co==256
  " HACK modify cssDefinition to add @cssColors to its contains
  redir => s:olddef
  silent!  syn list cssDefinition
  redir END
  if s:olddef != ''
    let s:b = strridx(s:olddef,'matchgroup')
    if s:b != -1
      exe 'syn region cssDefinition '.strpart(s:olddef,s:b).',@cssColors'
    endif
  endif
endif
