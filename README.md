tatap
================================================================================

Description
--------------------------------------------------------------------------------

_Tatap_ is an image viewer created with lightweight and high-speed operation in mind.

It is supposed to be linked to the extension and opened by double-clicking from your
favorite file manager.

By displaying the two images on the left and right,
you can also see manga in a two-page spread.
You can switch between right-to-left and left-to-right page turning.

Screenshot
--------------------------------------------------------------------------------

![Screenshot 1](tatap-screenshot-01.jpg "寄り添う3匹のうさぎのフリー素材 https://www.pakutaso.com/201701170163-16.html")

(Below) Spread display is also possible.

![Screenshot 2](tatap-screenshot-02.jpg "まんまる白うさぎのフリー素材 https://www.pakutaso.com/20170138016post-9992.html, 近寄るウサギのフリー素材 https://www.pakutaso.com/20130728189post-3005.html")

Key Combinations
--------------------------------------------------------------------------------

### General key combinations.

+ _Ctrl + N_  
  Open new window.
+ _Ctrl + W_  
  Close this window.
+ _Ctrl + Q_  
  Close all windows and quit this application.
+ _Ctrl + O_  
  Choose an image on your file system and open it.
+ _← (left arrow key)_  
  go backward (if the sort order is ascending)  
  go forward (if the sort order is descending)
+ _→ (right arrow key)_  
  go forward (if the sort order is ascending)  
  go backward (if the sort order is descending)

### Shortcut key in single view mode

+ _Ctrl + S_  
  Save this picture.
+ _Ctrl + Shift + S_  
  Save this picture as another name.
+ _Ctrl + 0_  
  Show this picture as original size
+ _Ctrl + 1_  
  Show this picture as fitting this window.
+ _Ctrl + +_  
  Zoom in
+ _Ctrl + -_  
  Zoom out
+ _Ctrl + H_  
  Invert horizontally
+ _Ctrl + V_  
  Invert vertically
+ _Ctrl + R_  
  Rotate 90 degrees clockwise
+ _Ctrl + L_  
  Rotate 90 degrees counterclockwise
+ _Ctrl + E_  
  Resize this picture. You can save it later.

### Buttons in dual view mode

+ ![1<](data/icons/symbolic/move-one-page-left-symbolic.svg)
  Move one page to the left.
+ ![2<<1_](data/icons/symbolic/read-right-to-left-symbolic.svg)
  Switch "from right to left" reading.
+ ![1>>2](data/icons/symbolic/read-left-to-right-symbolic.svg)
  Switch "from left to right" reading.
+ ![>1](data/icons/symbolic/move-one-page-right-symbolic.svg)
  Move one page to the right

Building and Installation
--------------------------------------------------------------------------------

You'll need the following dependencies:

* GCC
* CMake
* Python3
* Meson build system
* GTK+3 _(in Ubuntu, install libgtk-3-dev)_
* Vala compiler _(0.50 or later)_
* Gee (libgee-0.8 or later) _(in Ubuntu install libgee-0.8-dev)_
* Granite _(in Ubuntu install libgranite-dev)_

Run `meson build` to configure the build environment.
Add the build option `-DDEBUG=true` to log debug messages to a file.
Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `com.github.aharotias2.tatap`

    ninja install
    com.github.aharotias2.tatap
