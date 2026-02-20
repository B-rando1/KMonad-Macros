(defcfg
  ;; For Linux
  input  (device-file "/dev/input/event15")
  output (uinput-sink "My KMonad output"
    ;; To understand the importance of the following line, see the section on
    ;; Compose-key sequences at the near-bottom of this file.
    "/run/current-system/sw/bin/sleep 1 && /run/current-system/sw/bin/setxkbmap -option compose:ralt")
  cmp-seq ralt    ;; Set the compose key to `RightAlt'
  cmp-seq-delay 5 ;; 5ms delay between each compose-key sequence press

  ;; For Windows
  ;; input  (low-level-hook)
  ;; output (send-event-sink)

  ;; For MacOS
  ;; input  (iokit-name "my-keyboard-product-string")
  ;; output (kext)

  ;; Comment this if you want unhandled events not to be emitted
  fallthrough true

  ;; Set this to false to disable any command-execution in KMonad
  allow-cmd true

  ;; Set the implicit around to `around`
  implicit-around around
)

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
