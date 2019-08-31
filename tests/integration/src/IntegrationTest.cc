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

#include "session_manager.pb.h"
#include "session_manager.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::ClientReader;
using grpc::ClientReaderWriter;
using grpc::ClientWriter;
using grpc::Status;

using session_manager::GeolocationInput;
using session_manager::GeolocationOutput;
using session_manager::LoginInput;
using session_manager::LoginOutput;
using session_manager::LogoutInput;
using session_manager::LogoutOutput;
using session_manager::SessionManager;
using session_manager::UtteranceInput;
using session_manager::UtteranceOutput;

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

static void CheckParameter(int argc, char *argv[])
{
    string usage = "\n\n----------      Usage      ---------- \
                    \n    parameters: \
                    \n        argv[1]->Host address with the following format.IP - address V4 [0 - 255].[0 - 255].[0 - 255] \
                    \n        argv[2]->Host address server port with the following format.Number from 0 to 65535";                    

    // check if parameters count is right
    if(argc < 3)
        throw runtime_error((boost::format("Invalid number of arguments. Received: %d Expected: %d%s") % argc % 5 % usage).str());

    // check if server host address is null
    if (argv[1] == nullptr)
        throw runtime_error((boost::format("Host address is null") % usage).str());

    // check if server port is null
    if (argv[2] == nullptr)
        throw runtime_error((boost::format("Host address port is null") % usage).str());

    // This is bad host checking code and doesn't allow us to specify the container names.
    /*
    // Regex to test if the host address is valid
    regex host_address_regex("localhost|(\\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b)");
    
    // check if argv[2] is a valid host
    if (!regex_match(argv[1], host_address_regex))
    {
        throw runtime_error((boost::format("Host address is not a valid%s") % usage).str());
    }

    // Regex to test if the server port is valid
    regex host_address_port_regex("\\d*");

    // check if argv[3] is a valid port
    if (!regex_match(argv[2], host_address_port_regex) && atoi(argv[2]) < 65535 )
    {
        throw runtime_error((boost::format("Host address port is not valid%s") % usage).str());
    }*/
}

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

class SessionManagerClient
{
private:
    string _accessToken;
    string _user;
    string _password;

public:
    SessionManagerClient(std::shared_ptr<Channel> channel, const char *pInUser, const char *pInPassword) : stub_(SessionManager::NewStub(channel))
    {
        // set credentials for login and logout operations
        _user = string(pInUser);
        _password = string(pInPassword);
    }

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
        //pInInput->set_access_token(_accessToken);
        pInInput->set_utterance(pInUtterance);

        context.AddMetadata("access_token", _accessToken);

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

    
    void Geolocation(GeolocationInput *pInInput, GeolocationOutput *pOutOutput)
    {
        //TODO::implement this method
    }

    void EnhanceGeolocationInfo(GeolocationInput *pInInput, GeolocationOutput *pOutOutput)
    {
        //TODO::implement this method
    }

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
        rInput->set_username(_user.c_str());
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
        _accessToken = rOutput->access_token();

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "\tEnd setting access token";
        #endif
    }

    void Logout(LogoutInput *input, LogoutOutput *output)
    {
        //TODO::implement this method
    }

private:
    std::unique_ptr<SessionManager::Stub> stub_;
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
        string full_server_address = string(argv[1]) + ":" + string(argv[2]);
        std::shared_ptr<Channel> client_channel = grpc::CreateChannel(full_server_address.c_str(), grpc::InsecureChannelCredentials());

        // set test user credentials
        string user = "test";
        string password = "test";

        // create client object
        SessionManagerClient session_manager_client(client_channel, user.c_str(), password.c_str());

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "Testing the Login command.";
        #endif

        // try to login into the session manager server
        session_manager_client.Login();
        
        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "Login command is working correctly.";
            BOOST_LOG_TRIVIAL(debug) << "Testing the Utterance command.";
        #endif

        // start tests and let it fall into the exception 
        session_manager_client.Utterance("testing");

        #ifdef DEBUG_MODE
            BOOST_LOG_TRIVIAL(debug) << "Utterance command is working correctly.";
        #endif
    }
    catch (runtime_error e)
    {
        BOOST_LOG_TRIVIAL(fatal) << "---------- Fatal exception ----------\n\n" << e.what() << "\n\n";
        exit(1);
    }

    return 0;
}
