(declare-project
  :name "json-pure"
  :author "Techcable"
  :license "MIT AND CC0-1.0"
  :version "0.1.0"
  :repo "https://github.com/Techcable/janet-json-pure")

(declare-source
  # Registers in the `pure` directory, reflecting its difference
  # from the regular janet module.
  #
  # Given its generic name, this prefix is happily "shared" with other projects
  :prefix "pure"
  :source @["json.janet"])
