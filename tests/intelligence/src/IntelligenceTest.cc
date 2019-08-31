/*
 *
 * Copyright 2015 gRPC authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include <boost/format.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/utility/setup/file.hpp>
#include <boost/log/utility/setup/common_attributes.hpp>
#include <boost/algorithm/string.hpp>

#include <grpc/grpc.h>
#include <grpcpp/channel.h>
#include <grpcpp/client_context.h>
#include <grpcpp/create_channel.h>
#include <grpcpp/security/credentials.h>

#include <algorithm>
#include <stdio.h>
#include <regex>
#include <vector>
#include <utility>
#include <iostream>
#include <string>

#include "session_manager.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::ClientReader;
using grpc::ClientReaderWriter;
using grpc::ClientWriter;
using grpc::Status;

using session_manager_services::GeolocationInput;
using session_manager_services::GeolocationOutput;
using session_manager_services::LoginInput;
using session_manager_services::LoginOutput;
using session_manager_services::LogoutInput;
using session_manager_services::LogoutOutput;
using session_manager_services::PromptInput;
using session_manager_services::PromptOutput;
using session_manager_services::SessionManager;
using session_manager_services::UtteranceInput;
using session_manager_services::UtteranceOutput;

using namespace std;
namespace logging = boost::log;
namespace keywords = boost::log::keywords;
namespace attrs = boost::log::attributes;

// comment if debug is not desired
#define DEBUG_ENABLED

#ifdef DEBUG_ENABLED
    #ifndef DEBUG_MODE
        #define DEBUG_MODE
    #endif
#endif

/*
* CheckInputTestFile is used to check if the input test script is in the correct format.
* Input: const char *pInInputFilePath -> the path of the script file.
* Output: N/A
*/
static void CheckInputTestFile(const char *pInInputFilePath)
{
    // file descriptor
    FILE *rFile = fopen(pInInputFilePath, "r");

    // check if file descriptor was loaded
    if (rFile == nullptr)
        throw runtime_error("The file does not exist.");

    // variables to read the file
    char *rLine = NULL;
    size_t line_length = 0;
    int read_status = -1;
    int current_line = 0;
    string current_line_str = "";

    do
    {
        // get a u: <utterance> line
        read_status = getline(&rLine, &line_length, rFile); current_line++;

        // check if the read status is EOF with incomplete tests defined
        if(read_status == -1 && current_line == 0)
            throw runtime_error((boost::format("Read error: Expecting a 'u: <utterance>' in line %d Received: %s") % current_line % rLine).str());

        // break if it is reading EOF preceeded with valid arguments
        if(read_status == -1 && current_line > 1)
            break;

        // to facilitate ops
        current_line_str = string(rLine).substr(0, line_length - 1);
        current_line_str.erase(std::remove(current_line_str.begin(), current_line_str.end(), '\n'), current_line_str.end());

        // regex to check if the read line is describing an utterance
        regex utterance_regex("[U,u]\\s*:\\s*([a-z]+|[A-Z]+|[0-9]+).*");

        // check if the current line is an utterance
        if(!regex_match(current_line_str, utterance_regex))
            throw runtime_error((boost::format("Invalid input error: Expecting a 'u: <utterance>' in line %d Received: %s") % current_line % current_line_str).str());

        // get a va: <regex> line
        read_status = getline(&rLine, &line_length, rFile); current_line++;

        // to facilitate ops
        current_line_str = string(rLine).substr(0, line_length - 1);
        current_line_str.erase(std::remove(current_line_str.begin(), current_line_str.end(), '\n'), current_line_str.end());
        
        // check if the read status is EOF with incomplete tests defined
        if(read_status == -1)
            throw runtime_error((boost::format("Read error: Expecting a 'va: <regex>' in line %d Received: %s") % current_line % rLine).str());

        // regex to check if the read line is describing a regex
        regex regex_detection_regex("((va)|(VA)|(vA)|(Va))\\s*:\\s*([a-z]+|[A-Z]+|[0-9]+).*");

        // check if the current line is an utterance
        if(!regex_match(current_line_str, regex_detection_regex))
            throw runtime_error((boost::format("Invalid input error: Expecting a 'va: <regex>' in line %d Received: %s") % current_line % current_line_str).str());
    }while(read_status != -1);

    // close file
    fclose(rFile);

    // check if line has something that needs to be freed
    if (rLine)
        free(rLine);
}

/*
* CheckParameter is used to check if the input args are correct.
* Input: int argc -> number of arguments passed to the program.
*        char *argv[] -> arguments.
* Output: N/A
*/
static void CheckParameter(int argc, char *argv[])
{
    string usage = "\n\n----------      Usage      ---------- \
                    \n    parameters: \
                    \n        argv[1] -> Input test script with the following format with. \
                    \n\n            u: <utterance> \
                    \n            va : <regex> \
                    \n\n            This file may contains as many lines you want, but a 'va: <regex>' line must be preceeded by a 'u: <utterance>' one. \
                    \n\n \
                    \n        argv[2]->Host address with the following format.IP - address V4 [0 - 255].[0 - 255].[0 - 255] \
                    \n        argv[3]->Host address server port with the following format.Number from 0 to 65535 \
                    \n        argv[4]->Epochs number with the following format.Number from 1 to MAX_INT \
                    \n        argv[5]->Acceptance threshold is a number between 0 and 1";                    

    // check if parameters count is right
    if(argc < 6)
        throw runtime_error((boost::format("Invalid number of arguments. Received: %d Expected: %d%s") % argc % 5 % usage).str());

    // check if the test file is null
    if (argv[1] == nullptr) 
        throw runtime_error((boost::format("Input test script is null%s") % usage).str());

    // check if server host address is null
    if (argv[2] == nullptr)
        throw runtime_error((boost::format("Host address is null") % usage).str());

    // check if server port is null
    if (argv[3] == nullptr)
        throw runtime_error((boost::format("Host address port is null") % usage).str());

    // check if the number of epochs was especified
    if (argv[4] == nullptr)
        throw runtime_error((boost::format("Epochs quantity is null") % usage).str());

    // check if the threshold was defined
    if (argv[5] == nullptr)
        throw runtime_error((boost::format("Acceptance threshold is null") % usage).str());

    // check if the script is in the correct format
    try
    {
        CheckInputTestFile(argv[1]);
    }
    catch (runtime_error e)
    {
        throw runtime_error((boost::format("Input file is in the wrong format. \n\n%s \n\n%s") % e.what() % usage).str());
    }

    // Regex to test if the host address is valid
    regex host_address_regex("localhost|(\\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b)");
    
    // check if argv[2] is a valid host
    if (!regex_match(argv[2], host_address_regex))
    {
        throw runtime_error((boost::format("Host address is not a valid%s") % usage).str());
    }

    // Regex to test if the server port is valid
    regex host_address_port_regex("\\d*");

    // check if argv[3] is a valid port
    if (!regex_match(argv[3], host_address_port_regex) && atoi(argv[3]) < 65535 )
    {
        throw runtime_error((boost::format("Host address port is not valid%s") % usage).str());
    }

    // Regex to test the epochs quantity
    regex epoch_number_regex("[1-9][0-9]*");

    // check if argv[4] is a number that describe the total number of epochs to run
    if (!regex_match(argv[4], epoch_number_regex))
    {
        throw runtime_error((boost::format("Epoch parameter is not a number%s") % usage).str());
    }

    // Regex to test the epochs quantity
    regex threshold_regex("((0\\.[0-9]+)|(1\\.0+)|1|0)");

    // check if argv[4] is a number that describe the total number of epochs to run
    if (!regex_match(argv[5], threshold_regex))
    {
        throw runtime_error((boost::format("Invalid threshold%s") % usage).str());
    }
}

/*
* InitLogging is used to init the BOOST logger in order for it to write its outputs into a log file.
* Input: N/A
* Output: N/A
*/
static void InitLogging()
{
    logging::register_simple_formatter_factory<logging::trivial::severity_level, char>("Severity");

    logging::add_file_log(
        keywords::file_name = "client.log",
        keywords::format = "[%TimeStamp%] [%ThreadID%] [%Severity%] [%ProcessID%] [%LineID%] [%MyAttr%] [%CountDown%] %Message%");

    logging::core::get()->set_filter(
        logging::trivial::severity >= logging::trivial::info);

    logging::core::get()->add_global_attribute("MyAttr", attrs::constant<int>(42));
    logging::core::get()->add_global_attribute("CountDown", attrs::counter<int>(100, -1));

    logging::add_common_attributes();
}

/*
* SessionManagerClient class is the implementation of the SessionManager service.
*/
class SessionManagerClient
{
private:
    string _accessToken;
    string _user;
    string _password;

public:
    /*
    * SessionManagerClient constructor.
    * Input: shared_ptr<Channel> -> the connection between the GRPC SessionManager server and this client.
    *        const char *pÍnUser -> the username for this connection, it is used to login into the SessionManager.
    *        const char *pInPassword -> the password for this connection, it is used to login into the SessionManager.
    * Output: N/A
    */
    SessionManagerClient(std::shared_ptr<Channel> channel, const char *pInUser, const char *pInPassword) : stub_(SessionManager::NewStub(channel))
    {
        // set credentials for login and logout operations
        _user = string(pInUser);
        _password = string(pInPassword);
    }
	
    /*
    * Utterance is used to send an Utterance to the SessionManager and talk with the agent.
    * Input: const char *pInUtterance -> it is used as an input utterance to the agent.
    * Output: String -> utterance response from the SessionManager.
    */
    string Utterance(const char *pInUtterance)
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nstring Utterance(const char *pInUtterance) \
                        \n    input: \
                        \n        pInUtterance -> input utterance string. \
                        \n    output: \
                        \n        <string> -> server utterance response";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "SessionManagerClient | string Utterance(const char *pInUtterance)";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if the pInUtterance == nullptr";
        #endif

        if (pInUtterance == nullptr)
        {
            throw runtime_error((boost::format("SessionManagerClient | Utterance(%s) - pInUtterance cannot be a nullptr.%s") % pInUtterance % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if the pInUtterance == nullptr";
            BOOST_LOG_TRIVIAL(debug) << "\tCreating GRPC client context and utterance input and output objects";
        #endif

        // context for this client
        ClientContext context;

        // init the input and output parameters
        UtteranceInput *pInInput = new UtteranceInput();
        UtteranceOutput *pOutOutput = new UtteranceOutput();

        // set input parameters
        pInInput->set_token(_accessToken);
        pInInput->set_utterance(pInUtterance);

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd creating GRPC client context and utterance input and output objects";
            BOOST_LOG_TRIVIAL(debug) << "\tCalling the Utterance rpc from the stub";
        #endif

        // call the utterance command from the server
        Status status = stub_->Utterance(&context, *pInInput, pOutOutput);

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd calling the Utterance rpc from the stub";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking the GRPC operation status";
        #endif

        // check the call status and exit if any error
        if (!status.ok())
        {
            throw runtime_error((boost::format("SessionManagerClient | Utterance(%s) - GRPC error.\n\n-------GRPC-------\n\n%s \
                                                \n\n Tips: \
                                                \n\t 1) Try checking if the server is up. \
                                                \n\t 2) Check if you can ping the server from this client.") %
                                 pInUtterance % status.error_message())
                                    .str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking the GRPC operation status";
            BOOST_LOG_TRIVIAL(debug) << "\tReturning the output";
        #endif

        // return server response
        return string(pOutOutput->utterance());
    }

    /*
    * Prompt is used to ask if the agent has something to say to this client.
    * Input: PromptInput *pInInput -> the input parameter for this command, it includes the access token.
    * Output: PromptOutput *pOutOutput -> the output parameter for this command, it includes the received utterance from the agent.
    */
    void Prompt(PromptInput *pInInput, PromptOutput *pOutOutput)
    {
        //TODO::implement this method
    }

    /*
    * Geolocation is used to send the actual location of this client to the agent through the SessionManager.
    * Input: GeolocationInput *pInInput -> the input parameter includes the geolocation of this client and an access token.
    * Output: GeoLocationOutput *pOutOutput -> the output parameter for this command, it includes the status of the opperation.
    */
    void Geolocation(GeolocationInput *pInInput, GeolocationOutput *pOutOutput)
    {
        //TODO::implement this method
    }

    /*
    * EnhanceGeolocationInfo is used to send the actual location of this client to the agent through the SessionManager.
    * Input: GeolocationInput *pInInput -> the input parameter includes the geolocation of this client and an access token.
    * Output: GeoLocationOutput *pOutOutput -> the output parameter for this command, it includes the status of the opperation.
    */
    void EnhanceGeolocationInfo(GeolocationInput *pInInput, GeolocationOutput *pOutOutput)
    {
        //TODO::implement this method
    }

    /*
    * Login is used to login into the SessionManager.
    * Input: N/A
    * Output: N/A
    */
    void Login()
    {
        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "SessionManagerClient | Login()";
            BOOST_LOG_TRIVIAL(debug) << "\tCreating client context setting output and input variables";
        #endif

        // context for this client
        ClientContext context;

        // input and output variables to hold the parameters for this rpc call.
        LoginInput *rInput = new LoginInput();
        LoginOutput *rOutput = new LoginOutput();

        // set input parameters
        rInput->set_user(_user.c_str());
        rInput->set_password(_password.c_str());

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd creating client context and setting output and input variables";
            BOOST_LOG_TRIVIAL(debug) << "\tCalling the rpc Login command";
        #endif

        // call for the server with the login command
        Status status = stub_->Login(&context, *rInput, rOutput);

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd calling the rpc Login command";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if status is OK";
        #endif

        // check this call status
        if (!status.ok())
        {
            throw runtime_error((boost::format("SessionManagerClient | Login() - GRPC error.\n\n-------GRPC-------\n\n%s \
                                                \n\n Tips: \
                                                \n\t 1) Try checking if the server is up. \
                                                \n\t 2) Check if you can ping the server from this client. \
                                                \n\t 3) Check if you login and password are correct.") %
                                 status.error_message())
                                    .str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if status is OK";
            BOOST_LOG_TRIVIAL(debug) << "\tSetting access token...";
        #endif

        // set the output token to this object
        _accessToken = rOutput->token();

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd setting access token";
        #endif
    }

    /*
    * Logout is used to logout from the SessionManager.
    * Input: N/A
    * Output: N/A
    */
    void Logout(LogoutInput *input, LogoutOutput *output)
    {
        //TODO::implement this method
    }

private:
    std::unique_ptr<SessionManager::Stub> stub_;
};

class GhostTestObject
{
private:
    // total epochs to test
    int _totalEpochs;
    int _epochsMatchCount;
    int *_rTotalMatchCount;
    bool _testEnded;
    bool *_rRightEpochs;

    // variables to hold this test object statistics
    float *_rTestSuccessRate;
    float _rGlobalSuccessRate;

    // regex list to be tested
    vector<string> _regexExpressions;

    // input uterances string
    vector<string> _inputUtterances;

    // wrong utterances detected
    vector<pair<string, string>> *_wrongUtterances;

    // session manager instance to call for ghost
    SessionManagerClient *_rClient;

    /*
    * CalculateStatistics is used to calculate the statistics, error, success rate, for the Ghost's responses.
    * Input: N/A
    * Output: N/A
    */
    void CalculateStatistics()
    {
        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | CalculateStatistics()";
            BOOST_LOG_TRIVIAL(debug) << "\tCalculating statistics for each epoch";
        #endif

        for (int epoch = 0; epoch < _totalEpochs; epoch++)
        {
            // epoch statistics
            _rTestSuccessRate[epoch] = (float)_rTotalMatchCount[epoch] / (float)_regexExpressions.size();
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd calculating statistics for each epoch";
            BOOST_LOG_TRIVIAL(debug) << "\tCalculating global success rate";
        #endif

        // global statistics
        _rGlobalSuccessRate = (float)_epochsMatchCount / (float)_totalEpochs;

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd Calculating global success rate";
        #endif
    }

    /*
    * PrintStatistics is used to print all the calculated statistics.
    * Input: N/A
    * Output: N/A
    */
    void PrintStatistics()
    {
        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | PrintStatistics()";
        #endif

        // debug print the current epoch test
        BOOST_LOG_TRIVIAL(info) << "------------------- Statistics -------------------";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tPrinting statistics for each epoch";
        #endif

        // print statistics
        for (int epoch = 0; epoch < _totalEpochs; epoch++)
        {
            BOOST_LOG_TRIVIAL(info) << "Epoch " << epoch << " - correct " << _rTotalMatchCount[epoch] << " out of " << _regexExpressions.size() << " success rate: " << _rTestSuccessRate[epoch] * 100.0f << "%"
                                    << " error rate: " << (1.0 - _rTestSuccessRate[epoch]) * 100.0f << "%";

            #ifdef DEBUG_MODE
                BOOST_LOG_TRIVIAL(debug) << "\t\tPrinting statistics for each wrong utterance";
            #endif

            // print each wrong utterance
            for (int wrong_utterance = 0; wrong_utterance < _wrongUtterances[epoch].size(); wrong_utterance++)
            {
                BOOST_LOG_TRIVIAL(info) << "\tExpected: " << _wrongUtterances[epoch][wrong_utterance].first.c_str() << " Received: " << _wrongUtterances[epoch][wrong_utterance].second.c_str();
            }

            #ifdef DEBUG_MODE
                BOOST_LOG_TRIVIAL(debug) << "\t\tEnd printing statistics for each wrong utterance";
            #endif
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd printing statistics for each epoch";
            BOOST_LOG_TRIVIAL(debug) << "\tPrint global statistics";
        #endif

        // debug print the current epoch test
        BOOST_LOG_TRIVIAL(info) << "--------------- Global Statistics ---------------";
        BOOST_LOG_TRIVIAL(info) << "Correct epochs " << _epochsMatchCount << " out of " << _totalEpochs << " success rate: " << _rGlobalSuccessRate * 100.0f << "%"
                                << " error rate: " << (1.0 - _rGlobalSuccessRate) * 100.0f << "%";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd print global statistics";
        #endif
    }

    /*
    * LoadInputTestScript is used to load an input test script for the agent.
    * Input: const char *pInInputFilePath -> path in which the test script file is located.
    * Output: N/A
    */
    void LoadInputTestScript(const char *pInInputFilePath)
    {
        // file descriptor
        FILE *rFile = fopen(pInInputFilePath, "r");

        // variables to read the file
        char *rLine = NULL;
        size_t line_length = 0;
        int read_status = -1;
        int current_line = 0;
        string current_line_str = "";

        do
        {
            // get a u: <utterance> line
            read_status = getline(&rLine, &line_length, rFile); current_line++;

            // check if this line is EOF to avoid out of bounds or to sent trash to the server by storing it into 
            // this object tests array
            if(read_status == -1)
                break;

            // to facilitate ops
            current_line_str = string(rLine).substr(0, line_length - 1);
            current_line_str.erase(std::remove(current_line_str.begin(), current_line_str.end(), '\n'), current_line_str.end());
            
            // use string object to split with multi-char
            string delimiter = "u:";
            string utterance_string = current_line_str.substr(current_line_str.find(delimiter) + delimiter.length(), current_line_str.length() - delimiter.length());

            // get a va: <regex> line
            read_status = getline(&rLine, &line_length, rFile); current_line++;

            // to facilitate ops
            current_line_str = string(rLine).substr(0, line_length - 1);
            current_line_str.erase(std::remove(current_line_str.begin(), current_line_str.end(), '\n'), current_line_str.end());

            // use string object to split with multi-char
            delimiter = "va:";
            string regex_string = current_line_str.substr(current_line_str.find(delimiter) + delimiter.length(), current_line_str.length() - delimiter.length());

            // insert into output vector
            InsertRegexAndUtterance(regex_string.c_str(), utterance_string.c_str());
        }while(read_status != -1);

        // close file
        fclose(rFile);

        // check if line has something that needs to be freed
        if (rLine)
            free(rLine);
    }

public:
    /*
    * GhostStatistics is used to create an instance of this object.
    * Input: int epochs -> number of times this test object will run.
    *        const char *pIntestScript -> the test script file path to be loaded.
    *        SessionManagerClient *pInSessionManagerClient -> client used to call for the SessionManager through RPC calls.
    * Output: N/A
    */
    GhostTestObject(int epochs, const char *pInTestScript, SessionManagerClient *pInSessionManagerClient)
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nGhostTestObject(int epochs, const char *pInTestScript, SessionManagerClient *pInSessionManagerClient) \
                        \n    input: \
                        \n        epochs -> number of times this test object will run. \
                        \n        pIntestScript -> input script file \
                        \n        pInSessionManagerClient -> GRPC client. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | GhostTestObject()";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking epochs input";
        #endif

        // epochs cannot be zero
        if (epochs == 0)
        {
            throw runtime_error((boost::format("GhostTestObject | GhostTestObjects(%d, %d) - Epochs cannot be equals to zero.%s") % epochs % pInSessionManagerClient % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking epochs input";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if the session manager client is null";
        #endif

        // test if rInSessionManagerClient is a valid address
        if (pInSessionManagerClient == nullptr)
        {
            throw runtime_error((boost::format("GhostTestObject | GhostTestObjects(%d, %d) - pInSessionManagerClient cannot be null.%s") % epochs % pInSessionManagerClient % usage).str());
        }

        // load input file
        LoadInputTestScript(pInTestScript);

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if the session manager client is null";
            BOOST_LOG_TRIVIAL(debug) << "\tInitializing variables";
        #endif

        // set session manager client
        _rClient = pInSessionManagerClient;

        // set epochs
        _totalEpochs = epochs;

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd initializing variables";
            BOOST_LOG_TRIVIAL(debug) << "\tInitializing arrays";
        #endif

        // match count and statistics initialization
        _rTotalMatchCount = new int[_totalEpochs];
        _rRightEpochs = new bool[_totalEpochs];
        _rTestSuccessRate = new float[_totalEpochs];
        _wrongUtterances = new vector<pair<string, string>>[_totalEpochs];

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd initializing arrays";
            BOOST_LOG_TRIVIAL(debug) << "\tFilling arrays";
        #endif

        // epochs match
        _epochsMatchCount = 0;

        // init arrays c++ way
        fill(_rTotalMatchCount, _rTotalMatchCount + _totalEpochs, 0);
        fill(_rTestSuccessRate, _rTestSuccessRate + _totalEpochs, 0);
        fill(_rRightEpochs, _rRightEpochs + _totalEpochs, false);

        // set and test state variables
        _testEnded = false;

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd filling arrays";
        #endif
    }

    /*
    * InsertRegex is used add a regex and utterance pair that will be used to test agent's outputs.
    * input: const char* pInRegex -> the regex to be inserted.
    *        const char* pInUtterance -> utterance to be paired with the input regex.
    * output: N/A
    */
    void InsertRegexAndUtterance(const char *pInRegex, const char *pInUtterance)
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \n\nvoid InsertRegexAndUtterance(const char *pInRegex, const char *pInUtterance) \
                        \n    input: \
                        \n        pInRegex -> regex to be tested with a paired utterance string. \
                        \n        pInUtterance -> utterance string to be paired. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | InsertRegexAndUtterance(const char *pInRegex, const char *pInUtterance)";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if the regex is valid";
        #endif

        // epochs cannot be zero
        if (pInRegex == nullptr)
        {
            throw runtime_error((boost::format("GhostTestObject | InsertRegexAndUtterance(%d, %d) - pInRegex cannot be null.%s") % pInRegex % pInUtterance % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if the regex is valid";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if utterance is valid";
        #endif

        // test if rInSessionManagerClient is a valid address
        if (pInUtterance == nullptr)
        {
            throw runtime_error((boost::format("GhostTestObject | InsertRegexAndUtterance(%d, %d) - pInUtterance cannot be null.%s") % pInRegex % pInUtterance % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if utterance is valid";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if test have ended";
        #endif

        // if tests have endend, then throw an error since this operation will be useless
        if (_testEnded)
        {
            throw runtime_error((boost::format("GhostTestObject | InsertRegexAndUtterance(%d, %d) - tests have already been performed \
                                                it is useless to insert new reges and utterance pairs.%s") %
                                 pInRegex % pInUtterance % usage)
                                    .str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if test have ended";
        #endif

        /*
        * insert into both vector to avoid they to be in different sizes when 
        * performing tests.
        */

        // insert into the regex vector
        _regexExpressions.push_back(string(pInRegex));

        // insert into the utterance vector
        _inputUtterances.push_back(string(pInUtterance));
    }

    /*
    * GetGlobalSuccessRate is used get the global success rate of the agent - number of correct utterances.
    * input: N/A
    * output: float -> global success rate, a number in the following rage; [0, 1]
    */
    float GetGlobalSuccessRate()
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nfloat GetGlobalSuccessRate() \
                        \n    input: \
                        \n        None. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | GetGlobalSuccessRate()";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if performed tests correctly";
        #endif

        // check if tests have been performed
        if (!_testEnded)
        {
            throw runtime_error("GhostTestObject | GetGlobalSuccessRate() - Tests have not been performed yet.%s" + usage);
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if performed tests correctly";
        #endif

        return _rGlobalSuccessRate;
    }

    /*
    * GetGlobalErrorRate is used get the global error rate of the agent - number of wrong utterances.
    * input: N/A
    * output: float -> global error rate, a number in the following rage; [0, 1]
    */
    float GetGlobalErrorRate()
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nfloat GetGlobalErrorRate() \
                        \n    input: \
                        \n        None. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | GetGlobalErrorRate()";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if performed tests correctly";
        #endif

        // check if tests have been performed
        if (!_testEnded)
        {
            throw runtime_error("GhostTestObject | GetGlobalErrorRate() - Tests have not been performed yet.%s" + usage);
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if performed tests correctly";
        #endif

        return 1.0f - _rGlobalSuccessRate;
    }

    /*
    * GetSuccessRate is used get the success rate for a specific epoch.
    * input: int epoch -> epoch to get the success rate.
    * output: float -> success rate, a number in the range [0, 1], for the especified spoch.
    */
    float GetSuccessRate(int epoch)
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nfloat GetSuccessRate(int epoch) \
                        \n    input: \
                        \n        epoch -> epoch in which the success rate will be obtained. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | GetSuccessRate(int epoch)";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if epoch is valid";
        #endif

        // check if epoch is valid
        if (epoch >= _totalEpochs)
        {
            throw runtime_error((boost::format("GhostTestObject | GetSuccessRate(%d) - epoch is greater than what was defined for this object which is %d.%s") % epoch % _totalEpochs % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if epoch is valid";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if performed tests correctly";
        #endif

        // check if tests have been performed
        if (!_testEnded)
        {
            throw runtime_error((boost::format("GhostTestObject | GetSuccessRate(%d) - tests have not been performed yet.%s") % epoch % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if performed tests correctly";
        #endif

        return _rTestSuccessRate[epoch];
    }

    /*
    * GetErrorRate is used get the error rate for a specific epoch.
    * input: int epoch -> epoch to get the error rate.
    * output: float -> error rate, a number in the range [0, 1], for the especified spoch.
    */
    float GetErrorRate(int epoch)
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nfloat GetErrorRate(int epoch) \
                        \n    input: \
                        \n        epoch -> epoch in which the success rate will be obtained. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | GetErrorRate(int epoch)";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if epoch is valid";
        #endif

        // check if epoch is valid
        if (epoch >= _totalEpochs)
        {
            throw runtime_error((boost::format("GhostTestObject | GetErrorRate(%d) - epoch is greater than what was defined for this object which is %d.%s") % epoch % _totalEpochs % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if epoch is valid";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if tests have ended";
        #endif

        // check if tests have been performed
        if (!_testEnded)
        {
            throw runtime_error((boost::format("GhostTestObject | GetErrorRate(%d) - tests have not been performed yet.%s") % epoch % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if tests have ended";
        #endif

        return 1.0 - _rTestSuccessRate[epoch];
    }

    /*
    * StartTests is used start all the tests for the agent.
    * input: bool verbose -> boolean that when true will force this method to print the statistics after all tests are done.
    * output: N/A
    */
    void StartTests(bool verbose)
    {
        string usage = "\n\n----------      Usage      ---------- \
                        \nvoid StartTests(bool verbose) - perform all tests. \
                        \n    input: \
                        \n        verbose -> if true will print the statistics after the tests have ended. \
                        \n    output: \
                        \n        None.";

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "GhostTestObject | StartTests(bool verbose)";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if input utterances were set";
        #endif

        // throw error in case no utterance input was defined
        if (_inputUtterances.size() == 0)
        {
            throw runtime_error((boost::format("GhostTestObject | StartTests() - _inputUtterances.size() is equals to %ld%s") % _inputUtterances.size() % usage).str());
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if input utterances were set";
            BOOST_LOG_TRIVIAL(debug) << "\tChecking if tests have ended";
        #endif

        // already performed tests, you need to create a new instance of this test object
        if (_testEnded)
        {
            throw runtime_error("GhostTestObject | StartTests() - Already performed tests with this object it is useless to call this mehod again.%s" + usage);
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if tests have ended";
            BOOST_LOG_TRIVIAL(debug) << "\tEpochs loop";
        #endif

        // test loop for the defined expressions vector
        for (int epoch = 0; epoch < _totalEpochs; epoch++)
        {
            // debug print the current epoch test
            #ifdef DEBUG_MODE
                BOOST_LOG_TRIVIAL(debug) << "\tUtterances loop";
            #endif

            for (int test = 0; test < _inputUtterances.size(); test++)
            {
                try
                {
                    // try to call the utterance rpc for testing
                    string output_utterance = _rClient->Utterance(_inputUtterances[test].c_str());

                    // regex tests
                    regex expression(_regexExpressions[test]);

                    // debug print
                    #ifdef DEBUG_MODE
                        BOOST_LOG_TRIVIAL(debug) << "\tTesting the regex: " << _regexExpressions[test].c_str();
                        BOOST_LOG_TRIVIAL(debug) << "\tinput utterance: " << _inputUtterances[test].c_str();
                        BOOST_LOG_TRIVIAL(debug) << "\toutput utterance: " << output_utterance.c_str();
                    #endif

                    // check if this test is correct
                    if (regex_match(output_utterance, expression))
                    {
                        // increases the match counts for statistics
                        _rTotalMatchCount[epoch]++;
                    }
                    else
                    {
                        // insert this regex and utterance into the wrong ones vector
                        _wrongUtterances[epoch].push_back(pair<string, string>(_regexExpressions[test], output_utterance));
                    }

                    #ifdef DEBUG_MODE
                        BOOST_LOG_TRIVIAL(debug) << "\tEnd Testing the regex: " << _regexExpressions[test].c_str();
                        BOOST_LOG_TRIVIAL(debug) << "\tEnd input utterance: " << _inputUtterances[test].c_str();
                        BOOST_LOG_TRIVIAL(debug) << "\tEnd output utterance: " << output_utterance.c_str();
                    #endif
                }
                catch (runtime_error e)
                {
                    throw e;
                }
            }

            #ifdef DEBUG_MODE
                BOOST_LOG_TRIVIAL(debug) << "\tEnd utterances loop";
                BOOST_LOG_TRIVIAL(debug) << "\tChecking if all tests are ok";
            #endif

            // if succeed in all tests, increment one epoch to tell that this epochMatchCount is 100% right
            if (_rTotalMatchCount[epoch] == _inputUtterances.size())
            {
                // set this epoch boolean to know exactly which epoch is right
                _rRightEpochs[epoch] = true;

                // increment total matches for global statistics
                _epochsMatchCount++;
            }

            #ifdef DEBUG_MODE
                BOOST_LOG_TRIVIAL(debug) << "\tEnd checking if all tests are ok";
            #endif
        }

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd epochs loop";
            BOOST_LOG_TRIVIAL(debug) << "\tCalculate statistics";
        #endif

        // calculate statistics
        CalculateStatistics();

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd calculate statistics";
            BOOST_LOG_TRIVIAL(debug) << "\tPrint statistics";
        #endif

        // set flag to tell that all tests have ended correctly
        _testEnded = true;

        // if verbose is enable print all results
        if (verbose)
            PrintStatistics();

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd print statistics";
        #endif
    }
};

int main(int argc, char *argv[])
{
    // initialize boost logger
    // InitLogging();

    try
    {
        // check the parameters to avoid invalid input and test script files
        CheckParameter(argc, argv);

        // open channel with the server
        string full_server_address = string(argv[2]) + ":" + string(argv[3]);
        std::shared_ptr<Channel> client_channel = grpc::CreateChannel(full_server_address.c_str(), grpc::InsecureChannelCredentials());

        // set test user credentials
        string user = "test";
        string password = "test";

        // create client object
        SessionManagerClient session_manager_client(client_channel, user.c_str(), password.c_str());

        // try to login into the session manager server
        session_manager_client.Login();

        // total epochs to test
        int total_epochs = atoi(argv[4]);

        // tests threshold
        float acceptance_threshold = atof(argv[5]);

        // try to create a agent statistics and testing object
        GhostTestObject *pGhostTestObject = new GhostTestObject(total_epochs, argv[1], &session_manager_client);

        // set verbose variable so the statistics will be printed after the tests have ended
        bool verbose = true;

        // try to test the inserted utterances and regex for the defined number of epochs
        pGhostTestObject->StartTests(verbose);

        // check the tests success rate, if lower than the detection threshold, then return 1 to identify a failure
        if (pGhostTestObject->GetGlobalSuccessRate() < acceptance_threshold)
        {
            BOOST_LOG_TRIVIAL(info) << "Tests have failed, the global success rate was lower than an acceptance threshold equals to " << acceptance_threshold * 100.0f << "%";
            return 1;
        }
    }
    catch (runtime_error e)
    {
        BOOST_LOG_TRIVIAL(fatal) << "---------- Fatal exception ----------\n\n" << e.what() << "\n\n";
        exit(1);
    }

    return 0;
}
