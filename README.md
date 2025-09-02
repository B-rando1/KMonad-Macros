KMonad Macros is a project that I created mostly on a whim during exams, but has proven to be a fun learning experience with some useful applications. It introduces an extension to the [kmonad](https://github.com/kmonad/kmonad) language, and converts this extended language into valid kmonad code.

What does this extended langauge do? In addition to all of the existing features of stock kmonad, it allows you to also map keys to 'variables' and 'functions'. Variables are what they sound like - names that represent keypresses. Their values - the keypress represent - can be changed by functions.

Maybe an example would help. Here is the default keymapping for the the 8bitdo [Zero 2](https://www.8bitdo.com/zero2/) when it's in keyboard mode:

```
(defsrc
    k         m
    c         h
  e   f     i   g
    d   n o   j
)
```

I created a keymap to let me use it as a remote of sorts when reading or flipping through slides:
```
(deflayer readMode
     pp                   mute
     rght                 XX
  up      down       volu      vold
     left      XX XX      esc
)
```

It lets me scroll, control the music, and exit full screen (`esc`). The problem: not every app uses `esc` for fullscreen. Some use `esc`, some use `f11`, and some use `f`. So it would be nice if I could use some other keys to change the behaviour of this button to the various options.

This is technically possible with kmonad - we could define three separate layers that are exactly the same except for the fullscreen button, and use one of the currently unused keys to control the switching between layers. Or if we wanted to customize more keys, we could create a new layer to change each of them.

But that would be a lot of work! For each possible value for a key, you need to define an alternate version of every layer. And if you want to customize multiple keys, then you need an alternate layer for every combination of the keys!

Again, this is possible (and KMonad Macros does this under the hood), but a lot of repetitive, tedious work. Enter KMonad macros! Here is how we can accomplish our goal with it:

```
;; Define the fs_buttons type and the values it can take on
(deftypes
  (fs_buttons f11 esc f)
)

;; Define the $fullscreen variable to be of type fs_buttons
(defvars
  ($fullscreen fs_buttons)
)

;; Define functions to change the value of fs_buttons
(deffuncs
  (!fsF11 ($fullscreen f11))
  (!fsEsc ($fullscreen esc))
  (!fsF   ($fullscreen f))
)


(deflayer readMode
     pp                      mute
     rght                    (layer-switch readModeSettings)
  up      down          volu      vold
     left      XX XX       $fullscreen
)

(deflayer readModeSettings
         XX                  XX
         !fsF                layer-switch readMode
  !fsEsc        XX        XX    XX
         !fsF11    XX  XX    XX
)
```

With the first three blocks defining our types, variables, and functions, we can use the variables and functions in our layers. We have the original base layer, but instead of `esc` it references `$fullscreen`. It also has a key that switches the layer to the new `readModeSettings` layer. This layer has a key to go back to the main layer when finished, as well as three keys that call functions to change the value of `$fullscreen`.

With these changes in place, we can fully achieve our goal of changing the behaviour of the fullscreen key! And the best part: we can add layers and add new values to the `fs_buttons` type without needing to change any existing code!

This is obviously a very niche problem and a very odd solution, but it's been fun to develop, and dare I say, sometimes useful!
