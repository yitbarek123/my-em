import grpc
import concurrent.futures as futures
import time
import logging

from api import named_entity_recognition_pb2 as ner_pb2
from api import named_entity_recognition_pb2_grpc as ner_pb2_grpc


log = logging.getLogger("named_entity_test_server")

_ONE_DAY_IN_SECONDS = 60 * 60 * 24


class RecognizeEntityServicer(ner_pb2_grpc.RecognizeEntityServicer):

    def Recognize(self, request, context):
        return ner_pb2.EntityRecognitionOutput(value="Name")


class NamedEntityRecognitionServer:
    def __init__(self, port=50022):
        self.port = port
        self.server = None

    def start_server(self):
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
        ner_pb2_grpc.add_RecognizeEntityServicer_to_server(
            RecognizeEntityServicer(), self.server)
        self.server.add_insecure_port('[::]:{}'.format(self.port))
        self.server.start()
        log.info("Named entity recognition server at " + str(self.port))

    def stop_server(self):
        self.server.stop(0)


if __name__ == '__main__':
    server = NamedEntityRecognitionServer()
    server.start_server()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop_server()
