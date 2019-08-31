#!/usr/bin/tclsh

set cuisineList [list African American Arabic Argentinean Asian Australian Austrian Bar Barbecue Belgian Brazilian Brew British Burmese Cafe Cajun Canadian Caribbean Chinese Contemporary Creole Cuban Czech Danish Deli Eastern Egyptian Ethiopian European Fast Filipino French Fusion Gastropub German Gluten Greek Grill Halal Healthy Hungarian Indian Indonesian International Irish Israeli Italian Jamaican Japanese Korean Kosher Latin Lebanese Malaysian Mediterranean Mexican Moroccan Nepali Norwegian Persian Peruvian Pizza Polish Portuguese Pub Scandinavian Scottish Seafood Soups Spanish Steakhouse Street Sushi Swedish Taiwanese Thai Turkish Ukrainian Vegan Vegetarian Venezuelan Vietnamese Wine]

set count 1

proc toSCM {name number_of_reviews rank prices cuisines reviews city} {
    global RESTAURANT_NODE_NAME_PREFIX cuisineList count
    #puts "$name\n$number_of_reviews\n$rank\n$prices\n$cuisines\n$reviews\n$city"

set ff [open "rest.txt" "a"]
puts $ff $name
close $ff

    set word_nodes ""
    foreach word [split $name " "] {
        append word_nodes "    (WordNode \"$word\")\n        "
    }

    puts "
(EvaluationLink
    (PredicateNode \"VA: name\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (PhraseNode \"$name\")
    )
)"
    puts "
(EvaluationLink
    (PredicateNode \"VA: name-in-words\")
    (ListLink
        (PhraseNode \"$name\")
        (ListLink
        $word_nodes)
    )
)"

    puts "
(EvaluationLink
    (PredicateNode \"VA: number-of-reviews\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (NumberNode \"$number_of_reviews\")
    )
)"

    puts "
(EvaluationLink
    (PredicateNode \"VA: rank\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (NumberNode \"$rank\")
    )
)"

    foreach price $prices {
        puts "
(EvaluationLink
    (PredicateNode \"VA: prices\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (NumberNode \"[string length $price]\")
    )
)"
    }

    set f2 [open [format "%s_cuisines.txt" $RESTAURANT_NODE_NAME_PREFIX] "a"]
    foreach cuisine [split $cuisines " "] {
        puts $f2 $cuisine
        if {[lsearch $cuisineList $cuisine] != -1} {
            puts "
(EvaluationLink
    (PredicateNode \"VA: cuisine\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (WordNode \"$cuisine\")
    )
)"
        }
    }
    close $f2

    puts "
(EvaluationLink
    (PredicateNode \"VA: at-city\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (ConceptNode \"VA: $city\")
    )
)"

    foreach review $reviews {
        puts "
(EvaluationLink
    (PredicateNode \"VA: review\")
    (ListLink
        (RestaurantNode \"VA: restaurant-$RESTAURANT_NODE_NAME_PREFIX-$count\")
        (PhraseNode \"$review\")
    )
)"
    }
    incr count
}

proc clearChars {s} {
    return [regsub -all "\[^a-zA-Z0-9 \.\,/\]" $s ""]
}

foreach fname $argv {
    set RESTAURANT_NODE_NAME_PREFIX [lindex [split [lindex [split $fname "/"] end] "."] 0]
    set city {}
    foreach word [split $RESTAURANT_NODE_NAME_PREFIX "_"] {
        lappend city [string toupper [string index $word 0]]
        append city [string range $word 1 [string length $word]]
    }
    set f [open $fname "r"]
    while {[gets $f line] != -1} {
        if {! [string is ascii $line]} {
            continue
        }
        set name $line
        gets $f line
        if {(! [string is ascii $line]) || ([string compare [string index $line 0] " "])} {
            continue
        }
        set number_of_reviews [join [split [lindex [split [string trim $line] " "] 0] ","] ""]
        gets $f line
        set rank [string range [lindex [split $line " "] 0] 1 end]
        gets $f line
        set review {}
        set price {}
        set cuisine {}
        if {[string first "$" $line] == 0} {
            foreach word [split $line " -"] {
                if {[string compare $word ""]} {
                    if {[string first "$" $word] == 0} {
                        lappend price $word
                    } else {
                        lappend cuisine $word
                    }
                }
            }
            gets $f line
            lappend review [clearChars $line]
            gets $f line
            lappend review [clearChars $line]
        } else {
            lappend review [clearChars $line]
            gets $f line
            lappend review [clearChars $line]
        }
        toSCM $name $number_of_reviews $rank $price $cuisine $review $city
    }
    close $f
}

puts ""
foreach cuisine $cuisineList {
    puts "(InheritanceLink (WordNode \"$cuisine\") (WordNode \"cuisine\"))"
}
