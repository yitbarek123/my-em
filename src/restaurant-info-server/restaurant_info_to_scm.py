def single_info_to_scm(predicate, phrase, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "{}")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (PhraseNode "{}")))'.format(predicate, name_hash, phrase)


def name_to_scm(name, name_hash):
    return single_info_to_scm("name", name, name_hash)


def address_to_scm(address_str, name_hash):
    return single_info_to_scm("address", address_str, name_hash)


# TODO create methods for other single infos Rating, Price category,
# Number of reviews, Rank, Telephone and Site (eventually replacing
# the PhraseNode by NumberNode)

def cuisine_to_scm(cuisine, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "cuisine")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (PhraseNode "{}")))'.format(name_hash, cuisine)


def geolocation_to_scm(latitude, longitude, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "geolocation")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (ListLink' \
           '   (NumberNode {})' \
           '   (NumberNode {}))))'.format(name_hash, latitude, longitude)


def review_to_scm(review, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "reviews")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (ListLink (PhraseNode "{}"))))'.format(name_hash, review)


def rating_to_scm(rating, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "subrating")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (NumberNode {})))'.format(name_hash, rating)


def price_range_to_scm(lbound, ubound, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "price-range")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (IntervalLink' \
           '    (NumberNode {})' \
           '    (NumberNode {})))))'.format(name_hash, lbound, ubound)


# TODO make sure this returns the right format
def opening_hours_to_scm(interval, name_hash):
    return '(EvaluationLink' \
           ' (PredicateNode "price-range")' \
           '  (ListLink' \
           '   (ConceptNode "restaurant-{}")' \
           '   (ListLink' \
           '    (ConceptNode "weekday-tuesday")' \
           '    (TimeIntervalLink' \
           '     (TimeNode {})' \
           '     (TimeNode {})))))'.format(name_hash, interval[0], interval[1])


if __name__ == '__main__':
    print(price_range_to_scm(25, 50, "3232@fddf"))
    print(single_info_to_scm("fool", "foobar", "3232@fddf"))
    for rev in ["foo", "bar"]:
        print(review_to_scm(rev, "foobar@123"))
