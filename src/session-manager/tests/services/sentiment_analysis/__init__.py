import grpc
import concurrent.futures as futures
import time
import logging

from api import sentiment_analysis_pb2 as sa_pb2
from api import sentiment_analysis_pb2_grpc as sa_pb2_grpc


log = logging.getLogger("sentiment_analysis_test_server")

_ONE_DAY_IN_SECONDS = 60 * 60 * 24


class SentimentAnalysisServicer(sa_pb2_grpc.SentimentAnalysisServicer):

    def Analyze(self, request, context):
        return sa_pb2.SentimentAnalysisOutput(value="Positive")


class SentimentAnalysisServer:
    def __init__(self, port=50021):
        self.port = port
        self.server = None

    def start_server(self):
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
        sa_pb2_grpc.add_SentimentAnalysisServicer_to_server(
            SentimentAnalysisServicer(), self.server)
        self.server.add_insecure_port("[::]:{}".format(self.port))
        self.server.start()
        log.info("Sentiment analysis server at " + str(self.port))

    def stop_server(self):
        self.server.stop(0)


if __name__ == "__main__":
    server = SentimentAnalysisServer()
    server.start_server()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop_server()
