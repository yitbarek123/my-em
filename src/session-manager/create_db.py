import sys
import argparse
import json

from session_manager_admin import add_credential, add_service, set_db

if __name__ == "__main__":
    # This is a hack to have at least some kind of fixture loading in the short term.
    # Eventually we should used some standard library that allows us
    # to provide fixtures and do db migrations easily

    parser = argparse.ArgumentParser()
    parser.add_argument('--data', action='store', help='json file to load db entities from')
    parser.add_argument('--out', action='store', help='output file for sqlite db')
    
    args = parser.parse_args()

    with open(args.data, 'r') as f:
        data = json.load(f)

    set_db(args.out, db_create=True)
    
    for u in data['users']:
        add_credential(u['username'], u['password'])
    
    for s in data['services']:
        add_service(s['name'], s['host'], s['port'])
