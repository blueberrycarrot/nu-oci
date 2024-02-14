export def non-empty [] {
  is-empty | not $in
}

export def xray [comment --quote] {
  let input = $in
  print -en ($comment + ':')
  if ($input | describe) =~ '^(list|record|table)' {
    print -en "\n"
    print -e ($input | table -ed 2)
  } else {
    if $quote {
      print -e $' `($input)`'
    } else {
      print -e $' ($input)'
    }
  }
  $input
}
