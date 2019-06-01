;;; core.el --- the heart of the beast -*- lexical-binding: t; -*-

(eval-when-compile
  (and (version< emacs-version "25.3")
       (error "Detected Emacs %s. Doom only supports Emacs 25.3 and higher"
              emacs-version)))

(defvar doom-debug-mode (or (getenv "DEBUG") init-file-debug)
  "If non-nil, Doom will log more.

Use `doom/toggle-debug-mode' to toggle it. The --debug-init flag and setting the
DEBUG envvar will enable this at startup.")


;;
;;; Constants

(defconst doom-version "2.0.9"
  "Current version of Doom Emacs.")

(defconst EMACS26+ (> emacs-major-version 25))
(defconst EMACS27+ (> emacs-major-version 26))

(defconst IS-MAC     (eq system-type 'darwin))
(defconst IS-LINUX   (eq system-type 'gnu/linux))
(defconst IS-WINDOWS (memq system-type '(cygwin windows-nt ms-dos)))
(defconst IS-BSD     (or IS-MAC (eq system-type 'berkeley-unix)))


;;
(defvar doom-emacs-dir
  (eval-when-compile (file-truename user-emacs-directory))
  "The path to the currently loaded .emacs.d directory. Must end with a slash.")

(defvar doom-core-dir (concat doom-emacs-dir "core/")
  "The root directory of Doom's core files. Must end with a slash.")

(defvar doom-modules-dir (concat doom-emacs-dir "modules/")
  "The root directory for Doom's modules. Must end with a slash.")

(defvar doom-local-dir (concat doom-emacs-dir ".local/")
  "Root directory for local storage.

Use this as a storage location for this system's installation of Doom Emacs.
These files should not be shared across systems. By default, it is used by
`doom-etc-dir' and `doom-cache-dir'. Must end with a slash.")

(defvar doom-etc-dir (concat doom-local-dir "etc/")
  "Directory for non-volatile local storage.

Use this for files that don't change much, like server binaries, external
dependencies or long-term shared data. Must end with a slash.")

(defvar doom-cache-dir (concat doom-local-dir "cache/")
  "Directory for volatile local storage.

Use this for files that change often, like cache files. Must end with a slash.")

(defvar doom-packages-dir (concat doom-local-dir "packages/")
  "Where package.el and quelpa plugins (and their caches) are stored.

Must end with a slash.")

(defvar doom-docs-dir (concat doom-emacs-dir "docs/")
  "Where Doom's documentation files are stored. Must end with a slash.")

(defvar doom-private-dir
  (or (getenv "DOOMDIR")
      (let ((xdg-path
             (expand-file-name "doom/"
                               (or (getenv "XDG_CONFIG_HOME")
                                   "~/.config"))))
        (if (file-directory-p xdg-path) xdg-path))
      "~/.doom.d/")
  "Where your private configuration is placed.

Defaults to ~/.config/doom, ~/.doom.d or the value of the DOOMDIR envvar;
whichever is found first. Must end in a slash.")

(defvar doom-autoload-file (concat doom-local-dir "autoloads.el")
  "Where `doom-reload-doom-autoloads' stores its core autoloads.

This file is responsible for informing Emacs where to find all of Doom's
autoloaded core functions (in core/autoload/*.el).")

(defvar doom-package-autoload-file (concat doom-local-dir "autoloads.pkg.el")
  "Where `doom-reload-package-autoloads' stores its package.el autoloads.

This file is compiled from the autoloads files of all installed packages
combined.")

(defvar doom-env-file (concat doom-local-dir "env")
  "The location of your envvar file, generated by `doom env refresh`.

This file contains environment variables scraped from your shell environment,
which is loaded at startup (if it exists). This is helpful if Emacs can't
\(easily) be launched from the correct shell session (particularly for MacOS
users).")


;;
;;; Doom core variables

(defvar doom-init-p nil
  "Non-nil if Doom has been initialized.")

(defvar doom-init-time nil
  "The time it took, in seconds, for Doom Emacs to initialize.")

(defvar doom-emacs-changed-p nil
  "If non-nil, the running version of Emacs is different from the first time
Doom was setup, which may cause problems.")

(defvar doom-site-load-path (cons doom-core-dir load-path)
  "The initial value of `load-path', before it was altered by
`doom-initialize'.")

(defvar doom-site-process-environment process-environment
  "The initial value of `process-environment', before it was altered by
`doom-initialize'.")

(defvar doom-site-exec-path exec-path
  "The initial value of `exec-path', before it was altered by
`doom-initialize'.")

(defvar doom-site-shell-file-name shell-file-name
  "The initial value of `shell-file-name', before it was altered by
`doom-initialize'.")

(defvar doom--last-emacs-file (concat doom-local-dir "emacs-version.el"))
(defvar doom--last-emacs-version nil)
(defvar doom--refreshed-p nil)
(defvar doom--stage 'init)


;;
;;; Custom error types

(define-error 'doom-error "Error in Doom Emacs core")
(define-error 'doom-hook-error "Error in a Doom startup hook" 'doom-error)
(define-error 'doom-autoload-error "Error in an autoloads file" 'doom-error)
(define-error 'doom-module-error "Error in a Doom module" 'doom-error)
(define-error 'doom-private-error "Error in private config" 'doom-error)
(define-error 'doom-package-error "Error with packages" 'doom-error)


;;
;;; Custom hooks

(defvar doom-reload-hook nil
  "A list of hooks to run when `doom/reload' is called.")


;;
;;; Emacs core configuration

;; UTF-8 as the default coding system
(when (fboundp 'set-charset-priority)
  (set-charset-priority 'unicode))     ; pretty
(prefer-coding-system 'utf-8)          ; pretty
(setq locale-coding-system 'utf-8)     ; please
(unless IS-WINDOWS
  (setq selection-coding-system 'utf-8))  ; with sugar on top

(setq-default
 ad-redefinition-action 'accept   ; silence redefined function warnings
 apropos-do-all t                 ; make `apropos' more useful
 auto-mode-case-fold nil
 autoload-compute-prefixes nil
 debug-on-error doom-debug-mode
 jka-compr-verbose doom-debug-mode ; silence compression messages
 ffap-machine-p-known 'reject     ; don't ping things that look like domain names
 find-file-visit-truename t       ; resolve symlinks when opening files
 idle-update-delay 1              ; update ui slightly less often
 ;; be quiet at startup; don't load or display anything unnecessary
 inhibit-startup-message t
 inhibit-startup-echo-area-message user-login-name
 inhibit-default-init t
 initial-major-mode 'fundamental-mode
 initial-scratch-message nil
 ;; History & backup settings (save nothing, that's what git is for)
 auto-save-default nil
 create-lockfiles nil
 history-length 500
 make-backup-files nil  ; don't create backup~ files
 ;; byte compilation
 byte-compile-verbose doom-debug-mode
 byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local)
 ;; security
 gnutls-verify-error (not (getenv "INSECURE")) ; you shouldn't use this
 tls-checktrust gnutls-verify-error
 tls-program (list "gnutls-cli --x509cafile %t -p %p %h"
                   ;; compatibility fallbacks
                   "gnutls-cli -p %p %h"
                   "openssl s_client -connect %h:%p -no_ssl2 -no_ssl3 -ign_eof")
 ;; Don't store authinfo in plain text!
 auth-sources (list (expand-file-name "authinfo.gpg" doom-etc-dir)
                    "~/.authinfo.gpg")
 ;; Don't litter `doom-emacs-dir'
 abbrev-file-name             (concat doom-local-dir "abbrev.el")
 async-byte-compile-log-file  (concat doom-etc-dir "async-bytecomp.log")
 auto-save-list-file-name     (concat doom-cache-dir "autosave")
 backup-directory-alist       (list (cons "." (concat doom-cache-dir "backup/")))
 desktop-dirname              (concat doom-etc-dir "desktop")
 desktop-base-file-name       "autosave"
 desktop-base-lock-name       "autosave-lock"
 pcache-directory             (concat doom-cache-dir "pcache/")
 request-storage-directory    (concat doom-cache-dir "request")
 server-auth-dir              (concat doom-cache-dir "server/")
 shared-game-score-directory  (concat doom-etc-dir "shared-game-score/")
 tramp-auto-save-directory    (concat doom-cache-dir "tramp-auto-save/")
 tramp-backup-directory-alist backup-directory-alist
 tramp-persistency-file-name  (concat doom-cache-dir "tramp-persistency.el")
 url-cache-directory          (concat doom-cache-dir "url/")
 url-configuration-directory  (concat doom-etc-dir "url/")
 gamegrid-user-score-file-directory (concat doom-etc-dir "games/"))

(defun doom*symbol-file (orig-fn symbol &optional type)
  "If a `doom-file' symbol property exists on SYMBOL, use that instead of the
original value of `symbol-file'."
  (or (if (symbolp symbol) (get symbol 'doom-file))
      (funcall orig-fn symbol type)))
(advice-add #'symbol-file :around #'doom*symbol-file)


;;
;;; Minor mode version of `auto-mode-alist'

(defvar doom-auto-minor-mode-alist '()
  "Alist mapping filename patterns to corresponding minor mode functions, like
`auto-mode-alist'. All elements of this alist are checked, meaning you can
enable multiple minor modes for the same regexp.")

(defun doom|enable-minor-mode-maybe ()
  "Check file name against `doom-auto-minor-mode-alist'."
  (when (and buffer-file-name doom-auto-minor-mode-alist)
    (let ((name buffer-file-name)
          (remote-id (file-remote-p buffer-file-name))
          (alist doom-auto-minor-mode-alist))
      ;; Remove backup-suffixes from file name.
      (setq name (file-name-sans-versions name))
      ;; Remove remote file name identification.
      (when (and (stringp remote-id)
                 (string-match (regexp-quote remote-id) name))
        (setq name (substring name (match-end 0))))
      (while (and alist (caar alist) (cdar alist))
        (if (string-match-p (caar alist) name)
            (funcall (cdar alist) 1))
        (setq alist (cdr alist))))))
(add-hook 'find-file-hook #'doom|enable-minor-mode-maybe)


;;
;;; MODE-local-vars-hook

;; File+dir local variables are initialized after the major mode and its hooks
;; have run. If you want hook functions to be aware of these customizations, add
;; them to MODE-local-vars-hook instead.
(defun doom|run-local-var-hooks ()
  "Run MODE-local-vars-hook after local variables are initialized."
  (run-hook-wrapped (intern-soft (format "%s-local-vars-hook" major-mode))
                    #'doom-try-run-hook))
(add-hook 'hack-local-variables-hook #'doom|run-local-var-hooks)

;; If `enable-local-variables' is disabled, then `hack-local-variables-hook' is
;; never triggered.
(defun doom|run-local-var-hooks-if-necessary ()
  "Run `doom|run-local-var-hooks' if `enable-local-variables' is disabled."
  (unless enable-local-variables
    (doom|run-local-var-hooks)))
(add-hook 'after-change-major-mode-hook #'doom|run-local-var-hooks-if-necessary)

(defun doom|create-non-existent-directories ()
  "Automatically create missing directories when creating new files."
  (let ((parent-directory (file-name-directory buffer-file-name)))
    (when (and (not (file-exists-p parent-directory))
               (y-or-n-p (format "Directory `%s' does not exist! Create it?" parent-directory)))
      (make-directory parent-directory t))))
(add-hook 'find-file-not-found-functions #'doom|create-non-existent-directories)


;;
;;; Incremental lazy-loading

(defvar doom-incremental-packages '(t)
  "A list of packages to load incrementally after startup. Any large packages
here may cause noticable pauses, so it's recommended you break them up into
sub-packages. For example, `org' is comprised of many packages, and can be
broken up into:

  (doom-load-packages-incrementally
   '(calendar find-func format-spec org-macs org-compat
     org-faces org-entities org-list org-pcomplete org-src
     org-footnote org-macro ob org org-clock org-agenda
     org-capture))

This is already done by the lang/org module, however.

If you want to disable incremental loading altogether, either remove
`doom|load-packages-incrementally' from `emacs-startup-hook' or set
`doom-incremental-first-idle-timer' to nil.")

(defvar doom-incremental-first-idle-timer 2
  "How long (in idle seconds) until incremental loading starts.

Set this to nil to disable incremental loading.")

(defvar doom-incremental-idle-timer 1.5
  "How long (in idle seconds) in between incrementally loading packages.")

(defun doom-load-packages-incrementally (packages &optional now)
  "Registers PACKAGES to be loaded incrementally.

If NOW is non-nil, load PACKAGES incrementally, in `doom-incremental-idle-timer'
intervals."
  (if (not now)
      (nconc doom-incremental-packages packages)
    (when packages
      (let ((gc-cons-threshold doom-gc-cons-upper-limit)
            file-name-handler-alist)
        (let* ((reqs (cl-delete-if #'featurep packages))
               (req (ignore-errors (pop reqs))))
          (when req
            (doom-log "Incrementally loading %s" req)
            (condition-case e
                (or (while-no-input (require req nil t) t)
                    (push req reqs))
              ((error debug)
               (message "Failed to load '%s' package incrementally, because: %s"
                        req e)))
            (if reqs
                (run-with-idle-timer doom-incremental-idle-timer
                                     nil #'doom-load-packages-incrementally
                                     reqs t)
              (doom-log "Finished incremental loading"))))))))

(defun doom|load-packages-incrementally ()
  "Begin incrementally loading packages in `doom-incremental-packages'.

If this is a daemon session, load them all immediately instead."
  (if (daemonp)
      (mapc #'require (cdr doom-incremental-packages))
    (when (integerp doom-incremental-first-idle-timer)
      (run-with-idle-timer doom-incremental-first-idle-timer
                           nil #'doom-load-packages-incrementally
                           (cdr doom-incremental-packages) t))))

(add-hook 'window-setup-hook #'doom|load-packages-incrementally)


;;
;;; Bootstrap helpers

(defun doom-try-run-hook (hook)
  "Run HOOK (a hook function), but handle errors better, to make debugging
issues easier.

Meant to be used with `run-hook-wrapped'."
  (doom-log "Running doom hook: %s" hook)
  (condition-case e
      (funcall hook)
    ((debug error)
     (signal 'doom-hook-error (list hook e))))
  ;; return nil so `run-hook-wrapped' won't short circuit
  nil)

(defun doom-ensure-same-emacs-version-p ()
  "Check if the running version of Emacs has changed and set
`doom-emacs-changed-p' if it has."
  (if (load doom--last-emacs-file 'noerror 'nomessage 'nosuffix)
      (setq doom-emacs-changed-p
            (not (equal emacs-version doom--last-emacs-version)))
    (with-temp-file doom--last-emacs-file
      (princ `(setq doom--last-emacs-version ,(prin1-to-string emacs-version))
             (current-buffer))))
  (cond ((not doom-emacs-changed-p))
        ((y-or-n-p
          (format
           (concat "Your version of Emacs has changed from %s to %s, which may cause incompatibility\n"
                   "issues. If you run into errors, run `bin/doom compile :plugins` or reinstall your\n"
                   "plugins to resolve them.\n\n"
                   "Continue?")
           doom--last-emacs-version
           emacs-version))
         (delete-file doom--last-emacs-file))
        (noninteractive (error "Aborting"))
        ((kill-emacs))))

(defun doom-ensure-core-directories-exist ()
  "Make sure all Doom's essential local directories (in and including
`doom-local-dir') exist."
  (dolist (dir (list doom-local-dir doom-etc-dir doom-cache-dir doom-packages-dir))
    (unless (file-directory-p dir)
      (make-directory dir t))))

(defun doom|display-benchmark (&optional return-p)
  "Display a benchmark, showing number of packages and modules, and how quickly
they were loaded at startup.

If RETURN-P, return the message as a string instead of displaying it."
  (funcall (if return-p #'format #'message)
           "Doom loaded %s packages across %d modules in %.03fs"
           (length package-activated-list)
           (if doom-modules (hash-table-count doom-modules) 0)
           (or doom-init-time
               (setq doom-init-time (float-time (time-subtract (current-time) before-init-time))))))

(defun doom|run-all-startup-hooks ()
  "Run all startup Emacs hooks. Meant to be executed after starting Emacs with
-q or -Q, for example:

  emacs -Q -l init.el -f doom|run-all-startup-hooks"
  (run-hook-wrapped 'after-init-hook #'doom-try-run-hook)
  (setq after-init-time (current-time))
  (dolist (hook (list 'delayed-warnings-hook
                      'emacs-startup-hook 'term-setup-hook
                      'window-setup-hook))
    (run-hook-wrapped hook #'doom-try-run-hook)))

(defun doom-initialize-autoloads (file)
  "Tries to load FILE (an autoloads file). Return t on success, throws an error
in interactive sessions, nil otherwise (but logs a warning)."
  (condition-case e
      (load (file-name-sans-extension file) 'noerror 'nomessage)
    ((debug error)
     (if noninteractive
         (message "Autoload file warning: %s -> %s" (car e) (error-message-string e))
       (signal 'doom-autoload-error (list (file-name-nondirectory file) e))))))

(defun doom-load-env-vars (file)
  "Read and set envvars in FILE."
  (let (vars)
    (with-temp-buffer
      (insert-file-contents file)
      (re-search-forward "\n\n" nil t)
      (while (re-search-forward "\n\\([^= \n]+\\)=" nil t)
        (save-excursion
          (let ((var (match-string 1))
                (value (buffer-substring-no-properties
                        (point)
                        (1- (or (when (re-search-forward "^\\([^= ]+\\)=" nil t)
                                  (line-beginning-position))
                                (point-max))))))
            (setenv var value)))))
    vars))

(defun doom-initialize (&optional force-p)
  "Bootstrap Doom, if it hasn't already (or if FORCE-P is non-nil).

The bootstrap process involves making sure 1) the essential directories exist,
2) the core packages are installed, 3) `doom-autoload-file' and
`doom-package-autoload-file' exist and have been loaded, and 4) Doom's core
files are loaded.

If the cache exists, much of this function isn't run, which substantially
reduces startup time.

The overall load order of Doom is as follows:

  ~/.emacs.d/init.el
  ~/.emacs.d/core/core.el
  ~/.doom.d/init.el
  Module init.el files
  `doom-before-init-modules-hook'
  Module config.el files
  ~/.doom.d/config.el
  `doom-init-modules-hook'
  `after-init-hook'
  `emacs-startup-hook'
  `doom-init-ui-hook'
  `window-setup-hook'

Module load order is determined by your `doom!' block. See `doom-modules-dirs'
for a list of all recognized module trees. Order defines precedence (from most
to least)."
  (when (or force-p (not doom-init-p))
    (setq doom-init-p t)  ; Prevent infinite recursion

    ;; Reset as much state as possible
    (setq exec-path doom-site-exec-path
          load-path doom-site-load-path
          process-environment doom-site-process-environment
          shell-file-name doom-site-shell-file-name)

    ;; `doom-autoload-file' tells Emacs where to load all its autoloaded
    ;; functions from. This includes everything in core/autoload/*.el and all
    ;; the autoload files in your enabled modules.
    (when (or force-p (not (doom-initialize-autoloads doom-autoload-file)))
      (doom-ensure-core-directories-exist)
      (doom-ensure-same-emacs-version-p)

      (require 'core-packages)
      (doom-ensure-packages-initialized force-p)
      (doom-ensure-core-packages)

      (unless (or force-p noninteractive)
        (user-error "Your doom autoloads are missing! Run `bin/doom refresh' to regenerate them")))

    ;; Loads `doom-package-autoload-file', which loads a concatenated package
    ;; autoloads file and caches `load-path', `auto-mode-alist',
    ;; `Info-directory-list', `doom-disabled-packages' and
    ;; `package-activated-list'. A big reduction in startup time.
    (let (command-switch-alist)
      (unless (or force-p
                  (doom-initialize-autoloads doom-package-autoload-file)
                  noninteractive)
        (user-error "Your package autoloads are missing! Run `bin/doom refresh' to regenerate them")))

    ;; Load shell environment
    (when (and (not noninteractive)
               (file-readable-p doom-env-file))
      (doom-load-env-vars doom-env-file)
      (setq exec-path (append (split-string (getenv "PATH")
                                            (if IS-WINDOWS ";" ":"))
                              (list exec-directory))
            shell-file-name (or (getenv "SHELL")
                                shell-file-name))))

  (require 'core-lib)
  (require 'core-modules)
  (require 'core-os)
  (if noninteractive
      (require 'core-cli)
    (add-hook 'window-setup-hook #'doom|display-benchmark)
    (require 'core-keybinds)
    (require 'core-ui)
    (require 'core-projects)
    (require 'core-editor)))


;;
;;; Bootstrap Doom

(eval-and-compile
  (require 'subr-x)
  (require 'cl-lib)
  (unless EMACS26+
    (with-no-warnings
      ;; if-let and when-let were moved to (if|when)-let* in Emacs 26+ so we
      ;; alias them for 25 users.
      (defalias 'if-let* #'if-let)
      (defalias 'when-let* #'when-let))))

(add-to-list 'load-path doom-core-dir)

(doom-initialize noninteractive)
(unless noninteractive
  (doom-initialize-modules))
(with-eval-after-load 'package
  (require 'core-packages)
  (doom-initialize-packages))

(provide 'core)
;;; core.el ends here