;; -*- mode: emacs-lisp -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  "Configuration Layers declaration.
You should not put any user code in this function besides modifying the variable
values."
  (setq-default
   ;; Base distribution to use. This is a layer contained in the directory
   ;; `+distribution'. For now available distributions are `spacemacs-base'
   ;; or `spacemacs'. (default 'spacemacs)
   dotspacemacs-distribution 'spacemacs
   ;; Lazy installation of layers (i.e. layers are installed only when a file
   ;; with a supported type is opened). Possible values are `all', `unused'
   ;; and `nil'. `unused' will lazy install only unused layers (i.e. layers
   ;; not listed in variable `dotspacemacs-configuration-layers'), `all' will
   ;; lazy install any layer that support lazy installation even the layers
   ;; listed in `dotspacemacs-configuration-layers'. `nil' disable the lazy
   ;; installation feature and you have to explicitly list a layer in the
   ;; variable `dotspacemacs-configuration-layers' to install it.
   ;; (default 'unused)
   dotspacemacs-enable-lazy-installation 'unused
   ;; If non-nil then Spacemacs will ask for confirmation before installing
   ;; a layer lazily. (default t)
   dotspacemacs-ask-for-lazy-installation t
   ;; If non-nil layers with lazy install support are lazy installed.
   ;; List of additional paths where to look for configuration layers.
   ;; Paths must have a trailing slash (i.e. `~/.mycontribs/')
   dotspacemacs-configuration-layer-path '()
   ;; List of configuration layers to load.
   dotspacemacs-configuration-layers
   '(
     ;; ----------------------------------------------------------------
     ;; Example of useful layers you may want to use right away.
     ;; Uncomment some layer names and press <SPC f e R> (Vim style) or
     ;; <M-m f e R> (Emacs style) to install them.
     ;; ----------------------------------------------------------------
     ivy
     ;; helm
     (auto-completion :disabled-for org spacemacs-org)
     ;; better-defaults
     emacs-lisp
     common-lisp
     git
     ;; markdown
     ;; org
     ;; (shell :variables
     ;;        shell-default-height 30
     ;;        shell-default-position 'bottom)
     ;; spell-checking
     ;; syntax-checking
     ;; version-control
     ;; evil-russian
     ;; typescript
     semantic
     ;; chrome
     ;; emoji
     ;; elm
     ;; html
     javascript
     sql
     restclient
     yaml
     (haskell :variables haskell-process-type 'stack-ghci)
     anzem-config
     )
   ;; List of additional packages that will be installed without being
   ;; wrapped in a layer. If you need some configuration for these
   ;; packages, then consider creating a layer. You can also put the
   ;; configuration in `dotspacemacs/user-config'.
   dotspacemacs-additional-packages '(hledger-mode)
   ;; A list of packages that cannot be updated.
   dotspacemacs-frozen-packages '()
   ;; A list of packages that will not be installed and loaded.
   dotspacemacs-excluded-packages '(org-projectile evil-search-highlight-persist)
   ;; Defines the behaviour of Spacemacs when installing packages.
   ;; Possible values are `used-only', `used-but-keep-unused' and `all'.
   ;; `used-only' installs only explicitly used packages and uninstall any
   ;; unused packages as well as their unused dependencies.
   ;; `used-but-keep-unused' installs only the used packages but won't uninstall
   ;; them if they become unused. `all' installs *all* packages supported by
   ;; Spacemacs and never uninstall them. (default is `used-only')
   dotspacemacs-install-packages 'used-only))

(defun dotspacemacs/init ()
  "Initialization function.
This function is called at the very startup of Spacemacs initialization
before layers configuration.
You should not put any user code in there besides modifying the variable
values."
  ;; This setq-default sexp is an exhaustive list of all the supported
  ;; spacemacs settings.
  (setq-default
   ;; If non nil ELPA repositories are contacted via HTTPS whenever it's
   ;; possible. Set it to nil if you have no way to use HTTPS in your
   ;; environment, otherwise it is strongly recommended to let it set to t.
   ;; This variable has no effect if Emacs is launched with the parameter
   ;; `--insecure' which forces the value of this variable to nil.
   ;; (default t)
   dotspacemacs-elpa-https nil
   ;; Maximum allowed time in seconds to contact an ELPA repository.
   dotspacemacs-elpa-timeout 5
   ;; If non nil then spacemacs will check for updates at startup
   ;; when the current branch is not `develop'. Note that checking for
   ;; new versions works via git commands, thus it calls GitHub services
   ;; whenever you start Emacs. (default nil)
   dotspacemacs-check-for-update nil
   ;; If non-nil, a form that evaluates to a package directory. For example, to
   ;; use different package directories for different Emacs versions, set this
   ;; to `emacs-version'.
   dotspacemacs-elpa-subdirectory nil
   ;; One of `vim', `emacs' or `hybrid'.
   ;; `hybrid' is like `vim' except that `insert state' is replaced by the
   ;; `hybrid state' with `emacs' key bindings. The value can also be a list
   ;; with `:variables' keyword (similar to layers). Check the editing styles
   ;; section of the documentation for details on available variables.
   ;; (default 'vim)
   dotspacemacs-editing-style 'vim
   ;; If non nil output loading progress in `*Messages*' buffer. (default nil)
   dotspacemacs-verbose-loading nil
   ;; Specify the startup banner. Default value is `official', it displays
   ;; the official spacemacs logo. An integer value is the index of text
   ;; banner, `random' chooses a random text banner in `core/banners'
   ;; directory. A string value must be a path to an image format supported
   ;; by your Emacs build.
   ;; If the value is nil then no banner is displayed. (default 'official)
   dotspacemacs-startup-banner 'official
   ;; List of items to show in startup buffer or an association list of
   ;; the form `(list-type . list-size)`. If nil then it is disabled.
   ;; Possible values for list-type are:
   ;; `recents' `bookmarks' `projects' `agenda' `todos'."
   ;; List sizes may be nil, in which case
   ;; `spacemacs-buffer-startup-lists-length' takes effect.
   dotspacemacs-startup-lists '((recents . 5)
                                (projects . 7))
   ;; True if the home buffer should respond to resize events.
   dotspacemacs-startup-buffer-responsive t
   ;; Default major mode of the scratch buffer (default `text-mode')
   dotspacemacs-scratch-mode 'text-mode
   ;; List of themes, the first of the list is loaded when spacemacs starts.
   ;; Press <SPC> T n to cycle to the next theme in the list (works great
   ;; with 2 themes variants, one dark and one light)
   dotspacemacs-themes '(spacemacs-dark
                         spacemacs-light)
   ;; If non nil the cursor color matches the state color in GUI Emacs.
   dotspacemacs-colorize-cursor-according-to-state t
   ;; Default font, or prioritized list of fonts. `powerline-scale' allows to
   ;; quickly tweak the mode-line size to make separators look not too crappy.
   dotspacemacs-default-font '("Source Code Pro"
                               ;"Droid Sans Mono Slashed"
                               :size 15
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
   ;; The leader key
   dotspacemacs-leader-key "SPC"
   ;; The key used for Emacs commands (M-x) (after pressing on the leader key).
   ;; (default "SPC")
   dotspacemacs-emacs-command-key "SPC"
   ;; The key used for Vim Ex commands (default ":")
   dotspacemacs-ex-command-key ":"
   ;; The leader key accessible in `emacs state' and `insert state'
   ;; (default "M-m")
   dotspacemacs-emacs-leader-key "M-m"
   ;; Major mode leader key is a shortcut key which is the equivalent of
   ;; pressing `<leader> m`. Set it to `nil` to disable it. (default ",")
   dotspacemacs-major-mode-leader-key ","
   ;; Major mode leader key accessible in `emacs state' and `insert state'.
   ;; (default "C-M-m")
   dotspacemacs-major-mode-emacs-leader-key "C-M-m"
   ;; These variables control whether separate commands are bound in the GUI to
   ;; the key pairs C-i, TAB and C-m, RET.
   ;; Setting it to a non-nil value, allows for separate commands under <C-i>
   ;; and TAB or <C-m> and RET.
   ;; In the terminal, these pairs are generally indistinguishable, so this only
   ;; works in the GUI. (default nil)
   dotspacemacs-distinguish-gui-tab nil
   ;; If non nil `Y' is remapped to `y$' in Evil states. (default nil)
   dotspacemacs-remap-Y-to-y$ nil
   ;; If non-nil, the shift mappings `<' and `>' retain visual state if used
   ;; there. (default t)
   dotspacemacs-retain-visual-state-on-shift t
   ;; If non-nil, J and K move lines up and down when in visual mode.
   ;; (default nil)
   dotspacemacs-visual-line-move-text nil
   ;; If non nil, inverse the meaning of `g' in `:substitute' Evil ex-command.
   ;; (default nil)
   dotspacemacs-ex-substitute-global nil
   ;; Name of the default layout (default "Default")
   dotspacemacs-default-layout-name "Default"
   ;; If non nil the default layout name is displayed in the mode-line.
   ;; (default nil)
   dotspacemacs-display-default-layout nil
   ;; If non nil then the last auto saved layouts are resume automatically upon
   ;; start. (default nil)
   dotspacemacs-auto-resume-layouts nil
   ;; Size (in MB) above which spacemacs will prompt to open the large file
   ;; literally to avoid performance issues. Opening a file literally means that
   ;; no major mode or minor modes are active. (default is 1)
   dotspacemacs-large-file-size 1
   ;; Location where to auto-save files. Possible values are `original' to
   ;; auto-save the file in-place, `cache' to auto-save the file to another
   ;; file stored in the cache directory and `nil' to disable auto-saving.
   ;; (default 'cache)
   dotspacemacs-auto-save-file-location 'cache
   ;; Maximum number of rollback slots to keep in the cache. (default 5)
   dotspacemacs-max-rollback-slots 5
   ;; If non nil, `helm' will try to minimize the space it uses. (default nil)
   dotspacemacs-helm-resize nil
   ;; if non nil, the helm header is hidden when there is only one source.
   ;; (default nil)
   dotspacemacs-helm-no-header nil
   ;; define the position to display `helm', options are `bottom', `top',
   ;; `left', or `right'. (default 'bottom)
   dotspacemacs-helm-position 'bottom
   ;; Controls fuzzy matching in helm. If set to `always', force fuzzy matching
   ;; in all non-asynchronous sources. If set to `source', preserve individual
   ;; source settings. Else, disable fuzzy matching in all sources.
   ;; (default 'always)
   dotspacemacs-helm-use-fuzzy 'always
   ;; If non nil the paste micro-state is enabled. When enabled pressing `p`
   ;; several times cycle between the kill ring content. (default nil)
   dotspacemacs-enable-paste-transient-state nil
   ;; Which-key delay in seconds. The which-key buffer is the popup listing
   ;; the commands bound to the current keystroke sequence. (default 0.4)
   dotspacemacs-which-key-delay 0.4
   ;; Which-key frame position. Possible values are `right', `bottom' and
   ;; `right-then-bottom'. right-then-bottom tries to display the frame to the
   ;; right; if there is insufficient space it displays it at the bottom.
   ;; (default 'bottom)
   dotspacemacs-which-key-position 'bottom
   ;; If non nil a progress bar is displayed when spacemacs is loading. This
   ;; may increase the boot time on some systems and emacs builds, set it to
   ;; nil to boost the loading time. (default t)
   dotspacemacs-loading-progress-bar t
   ;; If non nil the frame is fullscreen when Emacs starts up. (default nil)
   ;; (Emacs 24.4+ only)
   dotspacemacs-fullscreen-at-startup nil
   ;; If non nil `spacemacs/toggle-fullscreen' will not use native fullscreen.
   ;; Use to disable fullscreen animations in OSX. (default nil)
   dotspacemacs-fullscreen-use-non-native nil
   ;; If non nil the frame is maximized when Emacs starts up.
   ;; Takes effect only if `dotspacemacs-fullscreen-at-startup' is nil.
   ;; (default nil) (Emacs 24.4+ only)
   dotspacemacs-maximized-at-startup nil
   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's active or selected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-active-transparency 90
   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's inactive or deselected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-inactive-transparency 90
   ;; If non nil show the titles of transient states. (default t)
   dotspacemacs-show-transient-state-title t
   ;; If non nil show the color guide hint for transient state keys. (default t)
   dotspacemacs-show-transient-state-color-guide t
   ;; If non nil unicode symbols are displayed in the mode line. (default t)
   dotspacemacs-mode-line-unicode-symbols t
   ;; If non nil smooth scrolling (native-scrolling) is enabled. Smooth
   ;; scrolling overrides the default behavior of Emacs which recenters point
   ;; when it reaches the top or bottom of the screen. (default t)
   dotspacemacs-smooth-scrolling t
   ;; Control line numbers activation.
   ;; If set to `t' or `relative' line numbers are turned on in all `prog-mode' and
   ;; `text-mode' derivatives. If set to `relative', line numbers are relative.
   ;; This variable can also be set to a property list for finer control:
   ;; '(:relative nil
   ;;   :disabled-for-modes dired-mode
   ;;                       doc-view-mode
   ;;                       markdown-mode
   ;;                       org-mode
   ;;                       pdf-view-mode
   ;;                       text-mode
   ;;   :size-limit-kb 1000)
   ;; (default nil)
   dotspacemacs-line-numbers '(:relative t :disabled-for-modes org-mode :size-limit-kb 1000)
   ;; Code folding method. Possible values are `evil' and `origami'.
   ;; (default 'evil)
   dotspacemacs-folding-method 'evil
   ;; If non-nil smartparens-strict-mode will be enabled in programming modes.
   ;; (default nil)
   dotspacemacs-smartparens-strict-mode nil
   ;; If non-nil pressing the closing parenthesis `)' key in insert mode passes
   ;; over any automatically added closing parenthesis, bracket, quote, etc…
   ;; This can be temporary disabled by pressing `C-q' before `)'. (default nil)
   dotspacemacs-smart-closing-parenthesis nil
   ;; Select a scope to highlight delimiters. Possible values are `any',
   ;; `current', `all' or `nil'. Default is `all' (highlight any scope and
   ;; emphasis the current one). (default 'all)
   dotspacemacs-highlight-delimiters 'all
   ;; If non nil, advise quit functions to keep server open when quitting.
   ;; (default nil)
   dotspacemacs-persistent-server nil
   ;; List of search tool executable names. Spacemacs uses the first installed
   ;; tool of the list. Supported tools are `ag', `pt', `ack' and `grep'.
   ;; (default '("ag" "pt" "ack" "grep"))
   dotspacemacs-search-tools '("ag" "pt" "ack" "grep")
   ;; The default package repository used if no explicit repository has been
   ;; specified with an installed package.
   ;; Not used for now. (default nil)
   dotspacemacs-default-package-repository nil
   ;; Delete whitespace while saving buffer. Possible values are `all'
   ;; to aggressively delete empty line and long sequences of whitespace,
   ;; `trailing' to delete only the whitespace at end of lines, `changed'to
   ;; delete only whitespace for changed lines or `nil' to disable cleanup.
   ;; (default nil)
   dotspacemacs-whitespace-cleanup nil
   ))

(defun dotspacemacs/user-init ()
  "Initialization function for user code.
It is called immediately after `dotspacemacs/init', before layer configuration
executes.
 This function is mostly useful for variables that need to be set
before packages are loaded. If you are unsure, you should try in setting them in
`dotspacemacs/user-config' first."
  ; make all agenda fonts the same
  (setq spacemacs-theme-org-agenda-height nil)
  ;(custom-set-faces
  ; '(org-agenda-done ((t (:foreground "#86dc2f" :height 1.0)))))
  ; '(org-agenda-done ((t (:height 1.0)))))
  ;(custom-set-faces
  ; '(org-scheduled-today ((t (:foreground "#bc6ec5" :height 1.0)))))
  )

(defun dotspacemacs/user-config ()
  "Configuration function for user code.
This function is called at the very end of Spacemacs initialization after
layers configuration.
This is the place where most of your configurations should be done. Unless it is
explicitly specified that a variable should be set before a package is loaded,
you should place your code here."

  ;;; GLOBAL KEYBINDINGS
  (global-set-key (kbd "C-;") 'evil-avy-goto-char)
  ;(spacemacs/set-leader-keys "oo" 'anzem/xah/open-file-fast)
  (spacemacs/set-leader-keys "ow" 'delete-other-windows)
  (spacemacs/set-leader-keys "wx" 'kill-buffer-and-window)
  (spacemacs/set-leader-keys "oc" 'quick-calc)


  ;;; GLOBAL SETTINGS
  (global-evil-surround-mode 1)
  (setq calendar-week-start-day 1)
  (setq ivy-initial-inputs-alist nil)
  ;; (set-fontset-font t 'unicode "Droid Sans" nil 'prepend)

  ;;; LOCALIZATION
  (defun anzem/localization-set-input-method-to-russian-computer () (set-input-method "russian-computer"))
  (add-hook 'org-mode-hook 'anzem/localization-set-input-method-to-russian-computer)
  (add-hook 'org-capture-mode-hook 'anzem/localization-set-input-method-to-russian-computer)

  (with-eval-after-load 'i3-ipc
    ;; возможно стоит запускать не shell команды, а процессы, чтобы каждый раз не инициализировался shell, тогда будет работать быстрее
    (i3-ipc-on-event "binding" payload
      (let ((key-pressed (bindat-get-field payload 'binding 'symbol)))
        (when (and (string= key-pressed "ISO_Next_Group")
                   (string= (string-trim (shell-command-to-string "xprop -id $(xdotool getactivewindow) WM_CLASS")) "WM_CLASS(STRING) = \"emacs\", \"Emacs\""))
          (call-process-shell-command "xkblayout-state set 0")
          (toggle-input-method)))))

  (with-eval-after-load 'sql
    (defconst anzem/sql-connection-string-prefix "--**--")

    (defun anzem/buffer-get-first-line ()
        (save-excursion (goto-char 1) (buffer-substring-no-properties 1 (line-end-position))))

    (defun anzem/sql-connection-component-from-string (str)
      (let* ((var-value-pair (split-string str ":" t " "))
            (var-name (car var-value-pair))
            (var-value (cadr var-value-pair))
            (var (pcase var-name
                        ("connection" :connection-name)
                        ((or "product" "user" "password" "port" "server" "database") (intern (concat "sql-" var-name))))))
        (pcase var
          ('sql-product (let ((product (intern var-value)))
                          (when (assoc product sql-product-alist)
                            `(,var (quote ,product)))))
          ('sql-port `(,var ,(string-to-number var-value)))
          (_ `(,var ,var-value)))))

    (defun anzem/remove-empty (list)
      (when (not (eq list nil))
        (if (eq (car list) nil)
            (anzem/remove-empty (cdr list))
          (cons (car list) (anzem/remove-empty (cdr list))))))

    (defun anzem/sql-parse-connection-string (str default-connection-name)
      (let* ((components (anzem/remove-empty (mapcar
                                              #'anzem/sql-connection-component-from-string
                                              (split-string str ";" t " "))))
            (connection-name (or (cadr (assq :connection-name components)) default-connection-name)))
        (cons connection-name (assq-delete-all :connection-name components))))


    (defun anzem/buffer-get-sql-connection-alist ()
      (let ((first-line (anzem/buffer-get-first-line)))
        (when (string-prefix-p anzem/sql-connection-string-prefix first-line)
          (anzem/remove-empty (mapcar (lambda (str) (anzem/sql-parse-connection-string str "default"))
                                      (split-string (string-remove-prefix anzem/sql-connection-string-prefix first-line) "|" t " "))))))

    (defun anzem/sql-connect-using-buffer-first-line (&optional args) (interactive)
          (let ((sql-connection-alist (anzem/buffer-get-sql-connection-alist)))
            (pcase (length sql-connection-alist)
              (1 (sql-connect (caar sql-connection-alist)))
              ((pred (lambda (x) (> x 1))) (sql-connect (sql-read-connection "Connection:"))))))

    (spacemacs/set-leader-keys-for-major-mode 'sql-mode "'" 'anzem/sql-connect-using-buffer-first-line))

  (with-eval-after-load 'org

    ;;; LOCALIZING REFILE DIALOG
    (defvar anzem/localization-is-org-refile-in-process nil)

    (defun anzem/localization-org-refile-before-advice (&rest args)
      (setq anzem/localization-is-org-refile-in-process t))
    (advice-add 'org-refile :before #'anzem/localization-org-refile-before-advice)

    (defun anzem/localization-org-refile-after-advice (&rest args)
      (setq anzem/localization-is-org-refile-in-process nil))
    (advice-add 'org-refile :after #'anzem/localization-org-refile-after-advice)

    (defun anzem/localization-minibuffer-setup-hook ()
      (when anzem/localization-is-org-refile-in-process (anzem/localization-set-input-method-to-russian-computer)))
    (add-hook 'minibuffer-setup-hook 'anzem/localization-minibuffer-setup-hook)

    (defun anzem/localization-minibuffer-exit-hook ()
      (setq anzem/localization-is-org-refile-in-process nil))
    (add-hook 'minibuffer-exit-hook 'anzem/localization-minibuffer-exit-hook))


  ;;; APPOINTMENTS
  (with-eval-after-load 'org
    (setq anzem/org-tag-regexp " *:[[:word:]:@_]*: *$") ; copied from toc-org-tags-regexp in order not to load toc-org.el
    (defun anzem/org-strip-tags-from-string (str)
      (if (string-match anzem/org-tag-regexp str) (replace-match "" nil nil str)
        str))

    (defun anzem/org-appt-disp-function (min-to-app new-time msg)
      (org-notify (format "⏰ %s %s"
                          (anzem/org-strip-tags-from-string msg)
                          (if (string= min-to-app "0") "now"
                            (format "in %s minutes" min-to-app)))))
    (setq appt-disp-window-function #'anzem/org-appt-disp-function)

    (defun anzem/org-play-appt-sound (message &optional play-sound)
      (when (string-prefix-p "⏰" message)
        (start-process-shell-command "play-appt-sound" nil "paplay ~/scripts/ding.wav")))
    (advice-add 'org-notify :after #'anzem/org-play-appt-sound)

    (setq
     appt-message-warning-time 2
     appt-display-interval 2)

    ;; need some timeout, or having "No event to add"
    (run-at-time "5 sec" nil 'org-agenda-to-appt))

  ;;; JS-MODE
  (with-eval-after-load 'js
    (setq js-indent-level 2))

  ;;; ORG-MODE
  (with-eval-after-load 'org
    (require 'org-checklist) ; to enable RESET_CHECK_BOXES property (to reset all checkboxes when repeating task is marked as done)


    ;; ORG-POMODORO SETTINGS
    ;(setq org-pomodoro-start-sound-p t)
    (setq org-pomodoro-clock-break t)
    (setq org-pomodoro-audio-player "/usr/bin/paplay")
    (setq org-pomodoro-keep-killed-pomodoro-time t)
    (setq org-pomodoro-long-break-length 15)
    (setq org-pomodoro-expiry-time 60)
    (advice-add 'org-pomodoro-start :before #'anzem/org-pomodoro-update-modeline-format)


    ;; ORG HELPER FUNCTIONS
    (defun anzem/org-get-scheduled-hm (pom)
      (let ((time-string (org-entry-get pom "SCHEDULED")))
        (when time-string
          (let* ((time-list (org-parse-time-string time-string))
                 (minute (cadr time-list))
                 (hour (caddr time-list)))
            (unless (= 0 hour minute)
              (format "%02d:%02d" hour minute))))))
    (defun anzem/org-schedule-tomorrow (&optional arg)
      (interactive)
      (org-schedule nil (concat "+1d " (anzem/org-get-scheduled-hm (point)))))
    (defun anzem/org-agenda-schedule-tomorrow (&optional arg)
      (interactive)
      (org-agenda-schedule nil (concat "+1d " (anzem/org-get-scheduled-hm (org-get-at-bol 'org-marker)))))
    (defun anzem/org-schedule-today (&optional arg) (interactive) (org-schedule nil "."))
    (defun anzem/org-schedule-remove () (interactive) (org-schedule '(4)))
    (defun anzem/org-schedule-today-if-todo (&optional arg) (interactive) (when (org-entry-is-todo-p) (anzem/org-schedule-today)))
    (defun anzem/org-schedule-today-if-not-scheduled ()
      (unless (org-entry-get nil "SCHEDULED")
        (anzem/org-schedule-today)))
    (defun anzem/org-jump-to-header (&optional arg) (interactive "P") (org-refile '(4)))
    (defun anzem/org-paste-to-new-line (&optional arg) (interactive) (evil-org-eol-call (lambda nil (clever-insert-item) (org-indent-line) (evil-paste-after))))
    (defun anzem/org-set-created-property ()
      (unless (org-entry-get nil "CREATED")
        (org-set-property "CREATED" (anzem/org-get-inactive-time-stamp))))
    (defun anzem/org-get-active-time-stamp (&optional without-time repeater)
      "Return current active timestamp. If optinal WITHOUT-TIME equals :without-time return timestamp with time. Use REPEATER if specified"
      (let* ((time-format (funcall (if (equal without-time :without-time) 'car 'cdr) org-time-stamp-formats))
             (time-format-with-repeater (if (not repeater) time-format
                                          (replace-regexp-in-string ">" (concat " " repeater ">") time-format))))
        (format-time-string time-format-with-repeater)))


    ;; ORG KEYBINDINGS
    (spacemacs/set-leader-keys-for-major-mode 'org-mode "g" 'org-goto)
    (spacemacs/set-leader-keys-for-major-mode 'org-mode "j" 'anzem/org-jump-to-header)
    (spacemacs/set-leader-keys-for-major-mode 'org-mode "oc" 'org-clock-goto)
    (spacemacs/set-leader-keys-for-major-mode 'org-mode "or" 'org-refile-goto-last-stored)
    (spacemacs/set-leader-keys-for-major-mode 'org-mode "ot" 'anzem/org-schedule-tomorrow)
    (spacemacs/set-leader-keys-for-major-mode 'org-mode "op" 'anzem/org-paste-to-new-line)
    (spacemacs/set-leader-keys-for-major-mode 'org-agenda-mode "c" 'org-capture)
    (spacemacs/set-leader-keys-for-major-mode 'org-agenda-mode "oc" 'org-agenda-clock-goto)
    (spacemacs/set-leader-keys-for-major-mode 'org-agenda-mode "ot" 'anzem/org-agenda-schedule-tomorrow)
    (spacemacs/set-leader-keys-for-major-mode 'org-agenda-mode "j" 'anzem/org-jump-to-header)
    ;; fixing spacemacs bug after org-mode update (see https://emacs.stackexchange.com/questions/48906/spacemacs-error-wrong-type-argument-commandp-org-set-tags-when-setting-tag):
    (spacemacs/set-leader-keys-for-major-mode 'org-mode ":" 'org-set-tags-command)


    ;; ORG SETTINGS
    (add-to-list 'org-modules 'org-habit)
    (add-to-list 'org-agenda-files (expand-file-name "~/org"))
    (setq org-enforce-todo-dependencies t)
    (setq org-enforce-todo-checkbox-dependencies t)
    (setq org-agenda-dim-blocked-tasks nil)
    (setq org-special-ctrl-a/e t)
    (setq org-clock-persist t) ; save the running clock and clock history when exiting emacs, load it on startup
    (setq org-refile-targets '((org-agenda-files . (:maxlevel . 6)))) ; add headings to refile dialog
    (setq org-refile-use-outline-path 'file) ; add filenames to refile dialog
    (setq org-outline-path-complete-in-steps nil) ; show full paths e.g. file.org/headline 1/headline 2 (convenient for use with completion packages)
    (setq org-refile-allow-creating-parent-nodes 'confirm) ; allow entering non existent headlines in refile dialog (these hedlines will be created)
    (setq org-blank-before-new-entry (quote ((heading) (plain-list-item)))) ; disable blank lines before and after new headings and new list items
    (setq org-goto-interface 'outline-path-completion) ; org-goto will ask for headline to jump in search dialog
    (setq org-deadline-warning-days 1)
    (setq org-log-repeat nil) ; do not insert timestamp in repeating task content when it was once again marked as done
    (setq org-clock-out-remove-zero-time-clocks t) ; remove clocking task with 0:00 duration
    (setq org-clock-report-include-clocking-task t) ; Include current clocking task in clock reports
    (setq org-clock-out-when-done nil) ; do not clock out when moving task to a done state
    (setq org-agenda-persistent-filter t) ; save agenda filters for current session
    (setq org-agenda-window-setup 'current-window)
    (setq org-agenda-span 'day) ; default to agenda day view
    (setq org-agenda-skip-scheduled-if-done t) ; do not show done items scheduled to current date
    (setq org-agenda-skip-deadline-if-done t) ; do not show done items with dedline expires by current date
    (org-clock-persistence-insinuate) ; resume clocking task when emacs is restarted
    (add-to-list 'org-global-properties '("Effort_ALL" . "0:15 0:30 1:00 1:30 2:00 2:30 3:00 3:30 4:00"))
    (setq org-columns-default-format "%TODO %170ITEM(TASK) %Effort(EFFORT){:} %CLOCKSUM")
    (setq org-todo-keywords '((sequence "TODO(t)" "|" "DONE(d)" "CANCELLED(c@/!)")))
    (setq org-default-notes-file (expand-file-name "~/org/45_inbox.org")) ; default file for capture
    (setq org-tag-alist '(;(:startgroup . nil)
                          ("5mBREAK" . ?1)
                          ("15mBREAK" . ?2)
                          ;("BACKLOG" . ?b)
                          ;(:endgroup . nil)
                          ("PHONE" . ?p)
                          ("COMP" . ?c)
                          ;("REVIEW" . ?r)
                          ("RUKO" . ?R)
                          ("SVETA" . ?S)
                          ("RYBINKOVY" . ?Y)
                          ("CHECKLIST" . ?C)
                          ("INFO" . ?I)))
    (setq org-capture-templates
       '(("c" "Some idea" entry (file "")
         "* %?\n\t:PROPERTIES:\n\t:CREATED: %U\n\t:END:" :no-save t)
        ("I" "Interruption" entry (file "")
         "* %?" :clock-in t :clock-resume t :no-save t)
        ("s" "To say (at meeting)" plain (file+regexp "40_skyeng.org" "\\*Обсудить на совещании:\\*")
         "- [ ] %?" :no-save t)
        ("n" "Notes about current clocking task" plain (clock)
         "- %U %?" :no-save t)))

    ;; OGR CUSTOM AGENDA COMMANDS
    (defun anzem/org-agenda-skip-if-scheduled-later ()
      "Stole this function here https://emacs.stackexchange.com/questions/29831/hide-scheduled-items-in-org-agenda-until-they-are-past-their-scheduled-date-and"
      (ignore-errors
        (let ((subtree-end (save-excursion (org-end-of-subtree t)))
              (scheduled-seconds
               (time-to-seconds
                (org-time-string-to-time
                 (org-entry-get nil "SCHEDULED"))))
              (now (time-to-seconds (current-time))))
          (and scheduled-seconds
               (>= scheduled-seconds now)
               subtree-end))))
    (setq org-agenda-custom-commands
          '(("n" "No contexts" agenda "" ((org-agenda-tag-filter-preset '("-SKYENG" "-5mBREAK" "-15mBREAK" "-COMP" "-PHONE"))))
            ("w" "Week review" agenda "" ((org-agenda-start-on-weekday nil) ;; calendar begins today
                                          (org-agenda-span 7) ;; view 7 days ahead
                                          (org-agenda-show-future-repeats nil)))
            ("1" "5 минут перерыв" tags-todo "5mBREAK" ((org-agenda-skip-function 'anzem/org-agenda-skip-if-scheduled-later)))
            ("2" "15 минут перерыв" tags-todo "15mBREAK" ((org-agenda-skip-function 'anzem/org-agenda-skip-if-scheduled-later)))
            ("t" "todo" agenda "" ((org-agenda-overriding-header "What To Do Now")
                                   (org-agenda-entry-types '(:scheduled :deadline))
                                   (org-agenda-time-grid nil)
                                   (org-agenda-skip-function 'anzem/org-agenda-skip-if-scheduled-later)))
            ("c" "За компом" ((agenda "")
                              (tags-todo "-SCHEDULED={.}"))
             ((org-agenda-tag-filter-preset '("+COMP"))))
            ("p" "Телефон в руках" tags-todo "PHONE+SCHEDULED<=\"<now>\"|PHONE-SCHEDULED={.}")
            ("v" "Vimbox" agenda "" ((org-agenda-tag-filter-preset '("+SKYENG"))))
            ("V" "No Vimbox" agenda "" ((org-agenda-tag-filter-preset '("-SKYENG"))
                                        (org-agenda-time-grid nil)))))
    (setq org-reverse-note-order t)

    ;;; ORG HOOKS AND ADVICES
    (add-hook 'org-insert-heading-hook 'anzem/org-set-created-property)

    (defvar anzem/org-change-state-from nil)
    (defvar anzem/org-change-state-to nil)
    (defun anzem/org-trigger-hook (change-plist)
      (let ((from (plist-get change-plist :from))
            (to (plist-get change-plist :to)))
        (setq anzem/org-change-state-from from)
        (setq anzem/org-change-state-to to)
        (cond ((string= to "TODO") (anzem/org-schedule-today-if-not-scheduled))
              ((eq to nil) (anzem/org-schedule-remove)))))
    (add-hook 'org-trigger-hook 'anzem/org-trigger-hook)

    (advice-add 'org-insert-todo-heading :after (lambda (arg &optional force-heading) "anzem/org-schedule-today-if-todo" (anzem/org-schedule-today-if-todo)))

    ;; ORG PROJECT PREFIX
    (defun anzem/org-add-prefix-to-new-heading ()
      "Add prefixt to headline derived from parent task \"PREFIX\" property"
      (let ((prefix (org-entry-get-with-inheritance "PREFIX")))
        (when (and prefix (not (string-prefix-p prefix (org-entry-get nil "ITEM"))))
          (beginning-of-line) ; нужно, чтобы следующая строка гарантированно переместила нас в место для префикса (без этого, в случае, когда мы уже в месте для префикса, она перемещает нас в самое начало строки)
          (let ((org-special-ctrl-a/e t)) (org-beginning-of-line)) ; переместит курсор в начало заголовка (но после тэгов и приоритета)
          (insert prefix ". "))))

    (defun anzem/org-end-of-line-if-evil-insert-state (&rest args)
      (when (evil-insert-state-p) (end-of-line)))

    (add-hook 'org-insert-heading-hook 'anzem/org-add-prefix-to-new-heading)
    (add-hook 'org-after-demote-entry-hook 'anzem/org-add-prefix-to-new-heading)
    (add-hook 'org-after-refile-insert-hook 'anzem/org-add-prefix-to-new-heading)
    (advice-add 'org-do-demote :after #'anzem/org-end-of-line-if-evil-insert-state)
    (advice-add 'org-insert-todo-heading :after #'anzem/org-end-of-line-if-evil-insert-state)


    ;; ORG FILES AUTOBACKUP
    (defun run-backup-and-push-org-files-shell-command-and-mark-hook-as-not-running ()
      (start-process "backup-and-push-org-files" "*Backup*" "/bin/bash" "/home/anzem/scripts/backup-and-push-org-files.sh")
      (setq is-after-save-hook-running nil))
    (defun backup-and-push-org-files-debounced ()
      (unless (or (bound-and-true-p is-after-save-hook-running) (not (string= (file-name-extension buffer-file-name) "org")))
        (setq is-after-save-hook-running t)
        (run-at-time 1 nil 'run-backup-and-push-org-files-shell-command-and-mark-hook-as-not-running)
        (message "Waiting debounce timeout...")))
    (add-hook 'after-save-hook 'backup-and-push-org-files-debounced)

    ;; ORG LINKS
    (defun anzem/org-follow-agenda-view-link (keys)
      (org-agenda nil keys))
    (org-add-link-type "agenda-view"  'anzem/org-follow-agenda-view-link)

    ;; ORG EDNA
    (defun org-edna-action/move-headline-in-subtree! (last-entry top-or-bottom) (anzem/org-move-headline-in-subtree top-or-bottom))

    (defun org-edna-action/schedule-today! (last-entry &optional force)
      (if (eq force :force)
          (anzem/org-schedule-today)
        (anzem/org-schedule-today-if-not-scheduled)))

    (defun org-edna-action/schedule-tomorrow! (last-entry)
      (anzem/org-schedule-tomorrow))

    (defun org-edna-action/prompt-property! (last-entry property)
      (unless (org-entry-get nil property) (org-entry-put nil property (read-string (concat "Specify " property ", please: ")))))

    (defun org-edna-action/prompt-effort! (last-entry &optional force)
      (unless (and (not (eq force :force)) (org-entry-get nil "EFFORT")) (org-set-effort)))

    (defun org-edna-action/prompt-tags! (last-entry &optional force)
      (when (or (eq force :force) (string-empty-p (org-get-tags-string))) (org-set-tags)))

    (defun anzem/org-get-effort-of-current-task () (org-entry-get nil org-effort-property))

    (defun anzem/org-add-explanation-for-overdue (clocked-time-in-minutes effort-in-minutes to-state from-state)
      (let* ((overdue-in-minutes (- clocked-time-in-minutes effort-in-minutes))
            (overdue-percent (/ (* overdue-in-minutes 100) effort-in-minutes)))
        (org-add-log-setup 'state to-state from-state 'note
                          (format-message "Время по задаче превышено на %d%% (%s/%s). Причина в том, что "
                                          overdue-percent
                                          (org-duration-from-minutes clocked-time-in-minutes)
                                          (org-duration-from-minutes effort-in-minutes)))))

    (defun anzem/if-overdue-explain (to-state from-state)
      (when (anzem/org-get-effort-of-current-task)
        (let ((clocked-time-in-minutes
              (if (equal org-clock-current-task (nth 4 (org-heading-components)))
                  (org-clock-get-clocked-time)
                  (org-clock-sum-current-item)))
              (effort-in-minutes (org-duration-to-minutes (anzem/org-get-effort-of-current-task))))
          (when (and (/= clocked-time-in-minutes 0) (> clocked-time-in-minutes effort-in-minutes))
            (anzem/org-add-explanation-for-overdue clocked-time-in-minutes effort-in-minutes to-state from-state)))))

    (defun org-edna-action/if-overdue-explain! (last-entry) (anzem/if-overdue-explain anzem/org-change-state-to anzem/org-change-state-from))

    (org-edna-load)

    (spacemacs/set-leader-keys-for-major-mode 'org-mode "oe" 'org-edna-edit))

    ;;; SLIME
  (push 'slime-repl-ansi-color slime-contribs))


;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("bffa9739ce0752a37d9b1eee78fc00ba1Палочку59748f50dc328af4be661484848e476" "fa2b58bb98b62c3b8cf3b6f02f058ef7827a8e497125de0254f56e373abee088" default)))
 '(evil-search-module (quote evil-search))
 '(evil-want-Y-yank-to-eol nil)
 '(org-log-note-headings
   (quote
    ((done . "CLOSING NOTE %t")
     (state . "State %-12s from %-12S %t")
     (note . "Заметка от %t")
     (reschedule . "Rescheduled from %S on %t")
     (delschedule . "Not scheduled, was %S on %t")
     (redeadline . "New deadline from %S on %t")
     (deldeadline . "Removed deadline, was %S on %t")
     (refile . "Refiled on %t")
     (clock-out . ""))))
 '(package-selected-packages
   (quote
    (web-beautify livid-mode skewer-mode simple-httpd json-mode json-snatcher json-reformat js2-refactor multiple-cursors js2-mode js-doc company-tern dash-functional tern coffee-mode smeargle orgit magit-gitflow magit-popup gitignore-mode gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link evil-magit magit transient git-commit with-editor ob-restclient ob-http company-restclient restclient know-your-http-well helm-themes helm-swoop helm-projectile helm-mode-manager helm-hoogle helm-flx helm-descbinds helm-company helm-c-yasnippet helm-ag ace-jump-helm-line sql-indent yaml-mode hledger-mode intero hlint-refactor hindent haskell-snippets company-ghci company-ghc ghc haskell-mode company-cabal cmm-mode lv web-mode tagedit slim-mode scss-mode sass-mode pug-mode haml-mode emmet-mode company-web web-completion-data xterm-color shell-pop multi-term eshell-z eshell-prompt-extras esh-help elm-mode reformatter emoji-cheat-sheet-plus company-emoji gmail-message-mode ham-mode markdown-mode html-to-markdown flymd edit-server stickyfunc-enhance srefactor tide typescript-mode flycheck fuzzy company-statistics company auto-yasnippet yasnippet ac-ispell auto-complete org-edna seq org-projectile org-category-capture org-present org-pomodoro alert log4e gntp org-mime org-download htmlize gnuplot ws-butler winum which-key wgrep volatile-highlights vi-tilde-fringe uuidgen use-package toc-org spaceline powerline smex restart-emacs request rainbow-delimiters popwin persp-mode pcre2el paradox spinner org-plus-contrib org-bullets open-junk-file neotree move-text macrostep lorem-ipsum linum-relative link-hint ivy-hydra indent-guide hydra hungry-delete hl-todo highlight-parentheses highlight-numbers parent-mode highlight-indentation helm-make helm helm-core google-translate golden-ratio flx-ido flx fill-column-indicator fancy-battery eyebrowse expand-region exec-path-from-shell evil-visualstar evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-lisp-state smartparens evil-indent-plus evil-iedit-state iedit evil-exchange evil-escape evil-ediff evil-args evil-anzu anzu evil goto-chg undo-tree eval-sexp-fu highlight elisp-slime-nav dumb-jump popup f dash s diminish define-word counsel-projectile projectile pkg-info epl counsel swiper ivy column-enforce-mode clean-aindent-mode bind-map bind-key auto-highlight-symbol auto-compile packed async aggressive-indent adaptive-wrap ace-window ace-link avy)))
 '(sql-connection-alist
   (quote
    (("motivation-profile-dev"
      (sql-product
       (quote postgres))
      (sql-user "ya_testing")
      (sql-database "vimbox_profile_auto_y9")
      (sql-server "localhost"))
     ("vimbox-resource-dev"
      (sql-product
       (quote postgres))
      (sql-user "ya_testing")
      (sql-database "vimbox_resource_auto_y9")
      (sql-server "localhost")))))
 '(truncate-lines t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
