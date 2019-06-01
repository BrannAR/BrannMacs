;;; core/doctor.el -*- lexical-binding: t; -*-

(defun file-size (file &optional dir)
  (setq file (expand-file-name file dir))
  (when (file-exists-p file)
    (/ (nth 7 (file-attributes file))
       1024.0)))

;; Check for oversized problem files in cache that may cause unusual/tremendous
;; delays or freezing. This shouldn't happen often.
(dolist (file (list "savehist"
                    "projectile.cache"))
  (let* ((path (expand-file-name file doom-cache-dir))
         (size (file-size path)))
    (when (and (numberp size) (> size 2000))
      (warn! "%s es demasiado grande (%.02fmb). Esto puede causar lentitud o inicios muy tardados."
             (file-relative-name path doom-core-dir)
             (/ size 1024))
      (explain! "Considera eliminarle de tu sistema (manualmente)"))))

(when (not (executable-find doom-projectile-fd-binary))
  (warn! "No se encontró el binario `fd'."))

(let ((default-directory "~"))
  (require 'projectile)
  (when (cl-find-if #'projectile-file-exists-p projectile-project-root-files-bottom-up)
    (warn! "Tu variable $HOME está siendo reconocida como la raíz del proyecto")
    (explain! "Brann will disable bottom-up root search, which may reduce the accuracy of project\n"
              "detection.")))

;; There should only be one
(when (and (file-equal-p doom-private-dir "~/.config/doom")
           (file-directory-p "~/.doom.d"))
  (warn! "%S Ni '~/.doom.d' existen en tu sistema."
         (abbreviate-file-name doom-private-dir))
  (explain! "Doom will only load one of these (~/.config/doom takes precedence). Since\n"
            "it is rarely intentional that you have both, ~/.doom.d should be removed."))
