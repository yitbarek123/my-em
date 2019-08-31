from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from .interface import Base


class Credential(Base):
    __tablename__ = "credential"
    username = Column(String(256),
                      primary_key=True,
                      unique=True,
                      nullable=False)
    password = Column(String(256), nullable=False)
    session_id = Column(Integer, default=0)
    active_device = Column(String(256), default="")
    devices = relationship("Device",
                           backref="credential",
                           lazy=True,
                           cascade="all, delete, delete-orphan",
                           single_parent=True)

    def __repr__(self):
        return "USERNAME     : {}\n" \
               "SESSION_ID   : {}\n" \
               "ACTIVE_DEVICE: {}\n" \
               "DEVICES      : {}\n".format(self.username,
                                            self.session_id,
                                            self.active_device,
                                            self.devices)


class Device(Base):
    __tablename__ = "devices"
    dev_id = Column(Integer, primary_key=True)
    device_name = Column(String(256),
                         nullable=False)
    access_token = Column(String(256), default="")
    username = Column(String(256),
                      ForeignKey("credential.username"),
                      nullable=False)

    def __repr__(self):
        return "USERNAME    : {}\n" \
               "DEVICE_NAME : {}\n" \
               "ACCESS_TOKEN: {}\n".format(self.username,
                                           self.device_name,
                                           self.access_token)


class Service(Base):
    __tablename__ = "service"
    service_name = Column(String(256), primary_key=True, unique=True)
    service_host = Column(String(256), nullable=False)
    service_port = Column(Integer, nullable=False)

    def __repr__(self):
        return "SERVICE_NAME: {}\n" \
               "SERVICE_HOST: {}\n" \
               "SERVICE_PORT: {}\n".format(self.service_name,
                                           self.service_host,
                                           self.service_port)
