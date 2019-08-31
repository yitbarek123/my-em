import sys
import os
import logging

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker


sm_root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
Base = declarative_base()


class Database:

    def __init__(self, db_file=None, db_create=False, log=None):
        self.db_file = db_file
        if db_file is None:
            self.db_file = "{}/sessions.db".format(sm_root_dir)
        self.engine = create_engine("sqlite:///{}".format(self.db_file),
                                    connect_args={'check_same_thread': False})
        if not os.path.exists(self.db_file) or db_create:
            self._create(drop=True)
        self.session = scoped_session(sessionmaker(bind=self.engine))()
        self.log = self._get_logger(log)

    def delete_db_file(self):
        if os.path.exists(self.db_file):
            self.log.warning("Deleting DB file '{}'".format(self.db_file))
            os.remove(self.db_file)

    @staticmethod
    def _get_logger(logger):
        if not logger:
            logging.basicConfig(stream=sys.stdout,
                                format="%(asctime)s - [%(levelname)8s] "
                                       "- %(name)s - %(message)s",
                                level=logging.INFO)
        return logging.getLogger("db_interface")

    def _create(self, drop=False):
        if drop:
            Base.metadata.drop_all(bind=self.engine)
        Base.metadata.create_all(bind=self.engine)

    def drop(self):
        Base.metadata.drop_all(bind=self.engine)

    def query(self, table, **kwargs):
        if kwargs:
            return self.session.query(table).filter_by(**kwargs).first()
        return self.session.query(table).first()

    def query_all(self, table, **kwargs):
        if kwargs:
            return self.session.query(table).filter_by(**kwargs).all()
        return self.session.query(table).all()

    def _add(self, table, **kwargs):
        if self.query(table, **kwargs):
            return False
        try:
            new_entry = table(**kwargs)
            self.session.add(new_entry)
            self.session.commit()
            return True
        except Exception as e:
            self.session.rollback()
            self.log.error(e)
            return False

    def _update(self, table, where, **update):
        try:
            if not self.query(table, **where):
                return False
            self.session.query(table).filter_by(**where).update(update)
            self.session.commit()
            return True
        except Exception as e:
            self.session.rollback()
            self.log.error(e)
            return False

    def _delete(self, table, **kwargs):
        try:
            entry = self.query(table, **kwargs)
            if not entry:
                return False
            self.session.delete(entry)
            self.session.commit()
            return True
        except Exception as e:
            self.session.rollback()
            self.log.error(e)
            return False

    def add(self, table, **kwargs):
        if not self._add(table, **kwargs):
            self.log.warning("Entry '{}' already exists in Table '{}'!".format(
                kwargs,
                table.__tablename__))
            return False
        return True

    def update(self, table, where, update):
        if not self._update(table, where, **update):
            self.log.warning("Entry '{}' not found in Table '{}'!".format(
                update,
                table.__tablename__))
            return False
        return True
    
    def refresh(self, obj):
        self.session.refresh(obj)

    def delete(self, table, **kwargs):
        if not self._delete(table, **kwargs):
            self.log.warning("Entry '{}' not found in Table '{}'!".format(
                kwargs,
                table.__tablename__))
            return False
        return True

    def print_table(self, table):
        for entry in self.query_all(table):
            self.log.info("\n" + str(entry))
