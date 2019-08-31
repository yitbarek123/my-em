#ifndef VA_SERVICE_H
#define VA_SERVICE_H

#include <vector>
#include "../OpencogSNETService.h"
#include <boost/lexical_cast.hpp>

#define S_UTTERANCE "utterance"
#define S_START_SESSION "start_session"
#define S_RESET "reset"
#define S_GEOLOCATION "geolocation"
#define S_PROMPT "prompt"
#define S_END_SESSION "end_session"

#define NOTHING 0
#define UTTERANCE 200
#define START_SESSION 201
#define RESET 202
#define GEOLOCATION 203
#define PROMPT 204
#define END_SESSION 205

#define VA_STATUS_OK true

#define VA_MSG_ERROR_INVALID_COMMAND "Invalid command."

#define VA_MSG_TOKENGRANT "Your token ID is: "
#define VA_MSG_SESSION_ENDED "Session ended."
#define VA_MSG_SESSION_DOES_NOT_EXIST "Session does not exist."
#define VA_MSG_DEFAULT_RESPONSE "I have nothing to say..."

#define VA_OP_URL_LOADED 100

#define VA_ERROR_CAN_NOT_LOAD_URL -100
#define VA_ERROR_CAN_NOT_LOAD_INVALID_SESSION -101
#define VA_ERROR_CAN_NOT_CREATE_FILE -102
#define VA_ERROR_CAN_NOT_DELETE_TEMP_FILE -103

namespace opencog_services
{
class VirtualAssistant : public OpencogSNETService
{
public:
    VirtualAssistant();
    ~VirtualAssistant();

    bool execute(std::string &rOutput, const std::vector<std::string> &rArgs) override;

private:
    void getResponse(const int token, std::string &rOutput, double attempts_time);
    int getCommand(const std::string &rCmdStr);
    void startSession(std::string &output, int *pInGhostID = nullptr);
    void reset(const int token, std::string &rOutput);
    void utterance(const int token, const std::string &rUtterance, std::string &rOutput);
    void geolocation(const int token, const std::string &rInGeolocation);
    void prompt(const int token, const std::string &rOutput);
    void endSession(const int token, std::string &rOutput);
};
} // namespace opencogservices
#endif
