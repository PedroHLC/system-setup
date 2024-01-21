{
  attrset = rec {
    overwrite = new: old: old // new;
    update = op: old: old // (op old);
    singleton = name: value: { "${name}" = value; };

    # ops => (name: value: accu: newValue)
    foldl = op: init: old:
      builtins.foldl'
        (accu: name: op name old.${name} accu)
        init
        (builtins.attrNames old);

    # `foldl` but swapping last two arguments, useful nested, e.g.:
    # foldl (parentName: foldl' (childName: value: overwrite ...)) { } { ... }
    foldl' = op: old: init: foldl op init old;
  };
}
