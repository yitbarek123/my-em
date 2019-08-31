#include "VirtualAssistant.h"
#include <ctime>
#include "../utils.h"
#include <stdio.h>
#include <string.h>

using namespace opencog_services;
using namespace std;

VirtualAssistant::VirtualAssistant()
{
}

VirtualAssistant::~VirtualAssistant()
{
}

void VirtualAssistant::startSession(string &rOutput, int *pInGhostID)
{
    int session_token = 0;

    vector<string> agents;
    vector<string> modules;

    string scheme_out = "";

    // try to start a new session
    createGuileSession(session_token, &modules, &agents, pInGhostID);

    evaluateScheme(scheme_out, "(add-to-load-path \"/\")", session_token);

    // load the virtual assistant engine
    evaluateScheme(scheme_out, "(use-modules (virtual-assistant virtual-assistant))", session_token);

    // runs http server and ghost main loop
    evaluateScheme(scheme_out, "(va-setup)", session_token);

    // set output to the user
    rOutput = to_string(session_token);
}

void VirtualAssistant::getResponse(const int token, std::string &rOutput, double wait_for_response_secs)
{
    string output = "";

    double elapsed_secs = 0.0;

    while(elapsed_secs < wait_for_response_secs) {
        auto start = chrono::steady_clock::now();

        evaluateScheme(output, string("(va-pop-vauttr)"), token);

        if (strstr(output.c_str(), "NOTHING") == nullptr) {
            rOutput.assign(output);
            return;
        }

        auto end = chrono::steady_clock::now();
        auto elapsed = end - start;

        elapsed_secs += chrono::duration <double, milli> (elapsed).count() / 1000.0;
    }

    rOutput.assign("I have nothing to say...");
}

void VirtualAssistant::utterance(const int token, const string &rUtterance, string &rOutput)
{
    // preparing ghost query cmd
    string cmd = "(va-push-request (list \"utterance\" \"" + rUtterance + "\"))";

    // send query to ghost
    evaluateScheme(rOutput, cmd, token);

    // read ghost response
    double wait_for_response_secs = 30.0;
    getResponse(token, rOutput, wait_for_response_secs);
}

void VirtualAssistant::reset(const int token, string &rOutput)
{
    // tell the virtual assistant engine to halt ghost loop
    string cmd = "(va-finalize)";
    evaluateScheme(rOutput, cmd, token);

    // close current session and keeping current id
    closeGuileSession(token, false);

    // starts a new session with the same ghost id
    int token_to_persist = token;
    startSession(rOutput, &token_to_persist);
}

void VirtualAssistant::endSession(const int token, std::string &rOutput)
{
    // tell the virtual assistant engine to halt ghost loop
    string cmd = "(va-finalize)";
    evaluateScheme(rOutput, cmd, token);

    // close current session and keeping current id
    closeGuileSession(token);
}

void VirtualAssistant::geolocation(const int token, const std::string &rInGeolocation) {
    // TODO::implement geolocation command
}

void VirtualAssistant::prompt(const int token, const std::string &rOutput) {
    // TODO::implement prompt command
}

int VirtualAssistant::getCommand(const string &rCmdStr)
{
    int command = NOTHING;

    if(rCmdStr == S_RESET)
        command = RESET;
    if(rCmdStr == S_UTTERANCE)
        command = UTTERANCE;
    if(rCmdStr == S_GEOLOCATION)
        command = GEOLOCATION;
    if(rCmdStr == S_START_SESSION)
        command = START_SESSION;
    if(rCmdStr == S_PROMPT)
        command = PROMPT;
    if(rCmdStr == S_END_SESSION)
        command = END_SESSION;

    return command;
}

bool VirtualAssistant::execute(string &rOutput, const vector<string> &rArgs)
{
    // bot response
    string response = "";

    // try to parse command if any is received
    int command = getCommand(rArgs[0]);
    bool status = true;

    switch (command) {
        case UTTERANCE:
            utterance(atoi(rArgs[1].c_str()), rArgs[2], response);
            break;
        case START_SESSION:
            startSession(response);
            break;
        case RESET:
            reset(atoi(rArgs[1].c_str()), response);
            break;
        case PROMPT:
            // TODO::implement prompt
            response = "Response from the prompt command.";
            break;
        case GEOLOCATION:
            // TODO::implement geolocation
            response = "Response from the geolocation command.";
            break;
        case END_SESSION:
            endSession(atoi(rArgs[1].c_str()), response);
            break;
        default:
            response = string(VA_MSG_ERROR_INVALID_COMMAND);
            status = false;
            break;
    }

    // set default response if none is obtained from the system
    if (response.length() == 0) {
        response = string(VA_MSG_DEFAULT_RESPONSE);
    }

    // set output to the user
    rOutput = response;

    return status;
}
