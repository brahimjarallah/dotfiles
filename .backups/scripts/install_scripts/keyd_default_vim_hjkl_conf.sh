# copy to => /etc/keyd/default.conf


[ids]
*

[main]
# Alt key becomes an overlay for vim-style navigation
leftalt = overload(nav, leftalt)

[nav]
# ===== YOUR VIM MAPPINGS =====
# Basic vim navigation (Alt+hjkl)
h = left
j = down
k = up
l = right

# Word navigation (Alt+Ctrl+h/l)
control+h = C-left
control+l = C-right

# Line navigation (Alt+Ctrl+j/k)
control+j = end
control+k = home

# Document navigation (Alt+Shift+j/k)
shift+j = C-end
shift+k = C-home

# Page navigation (Alt+Ctrl+Shift+j/k)
shift+control+j = pagedown
shift+control+k = pageup

# Selection with vim keys (Alt+Shift+hjkl)
shift+h = S-left
shift+l = S-right

# Word selection (Alt+Ctrl+Shift+h/l)
shift+control+h = C-S-left
shift+control+l = C-S-right

# Delete operations
x = delete
control+x = C-delete

# Quick save/undo
s = C-s
z = C-z
shift+z = C-y

# ===== ALL OTHER ALT COMBINATIONS (PASSTHROUGH) =====
# Arrow keys
up = A-up
down = A-down
left = A-left
right = A-right

# Function keys
f1 = A-f1
f2 = A-f2
f3 = A-f3
f4 = A-f4
f5 = A-f5
f6 = A-f6
f7 = A-f7
f8 = A-f8
f9 = A-f9
f10 = A-f10
f11 = A-f11
f12 = A-f12

# Numbers
1 = A-1
2 = A-2
3 = A-3
4 = A-4
5 = A-5
6 = A-6
7 = A-7
8 = A-8
9 = A-9
0 = A-0

# Letters (except h,j,k,l,s,x,z which are your vim keys)
a = A-a
b = A-b
c = A-c
d = A-d
e = A-e
f = A-f
g = A-g
i = A-i
m = A-m
n = A-n
o = A-o
p = A-p
q = A-q
r = A-r
t = A-t
u = A-u
v = A-v
w = A-w
y = A-y

# Special keys
tab = A-tab
enter = A-enter
space = A-space
backspace = A-backspace
delete = A-delete
home = A-home
end = A-end
pageup = A-pageup
pagedown = A-pagedown
insert = A-insert

# Punctuation
comma = A-comma
period = A-period
slash = A-slash
backslash = A-backslash
semicolon = A-semicolon
apostrophe = A-apostrophe
grave = A-grave
minus = A-minus
equal = A-equal
leftbrace = A-leftbrace
rightbrace = A-rightbrace

# With Shift modifier
shift+up = A-S-up
shift+down = A-S-down
shift+left = A-S-left
shift+right = A-S-right
shift+tab = A-S-tab
shift+enter = A-S-enter
shift+space = A-S-space
shift+backspace = A-S-backspace
shift+delete = A-S-delete
shift+home = A-S-home
shift+end = A-S-end
shift+pageup = A-S-pageup
shift+pagedown = A-S-pagedown

# With Ctrl modifier (except your custom ones)
control+up = A-C-up
control+down = A-C-down
control+left = A-C-left
control+right = A-C-right
control+tab = A-C-tab
control+enter = A-C-enter
control+space = A-C-space
control+backspace = A-C-backspace
control+delete = A-C-delete
control+home = A-C-home
control+end = A-C-end
control+pageup = A-C-pageup
control+pagedown = A-C-pagedown

# Numbers with modifiers
shift+1 = A-S-1
shift+2 = A-S-2
shift+3 = A-S-3
shift+4 = A-S-4
shift+5 = A-S-5
shift+6 = A-S-6
shift+7 = A-S-7
shift+8 = A-S-8
shift+9 = A-S-9
shift+0 = A-S-0

control+1 = A-C-1
control+2 = A-C-2
control+3 = A-C-3
control+4 = A-C-4
control+5 = A-C-5
control+6 = A-C-6
control+7 = A-C-7
control+8 = A-C-8
control+9 = A-C-9
control+0 = A-C-0
