[req-spec]: https://docs.google.com/document/d/1a8vSoub6wmDunaYbTe-I9rTUm69AawIeAOd-cKGl7Sk/edit#heading=h.ozc0t6guimrh
[docker-site]: https://www.docker.com
[singularitynet-home]: https://www.singularitynet.io
[cn5-repo]: https://github.com/singnet/conceptnet-server
[sumo-repo]: https://github.com/singnet/sumo-server
[ner-service]: https://github.com/singnet/nlp-services/tree/master/named-entity-recognition
[sa-service]: https://github.com/singnet/nlp-services/tree/master/sentiment-analysis
[app-repo]: https://github.com/singnet/virtual-assistant-android
[unity-site]: https://docs.unity3d.com/Manual/android-GettingStarted.html
[ghost-readme]: https://github.com/opencog/opencog/tree/master/opencog/ghost
[relex-repo]: https://github.com/opencog/relex
[r2l-readme]: https://github.com/opencog/opencog/tree/master/opencog/nlp/relex2logic

![singnetlogo](assets/singnet-logo.jpg 'SingularityNET')

[![CircleCI](https://circleci.com/gh/singnet/virtual-assistant.svg?style=svg&circle-token=874a515292a7639e04ce4dda9a81eb89583bfcee)](https://circleci.com/gh/singnet/virtual-assistant)

# Virtual Assistant

This is an OpenCog-powered personal assistant customizable to different
application contexts (smartphones, desktop, IoT etc).

## 1. Github project organization

This repository contains the source code for the AI engine of Virtual Assistant as well as resources for its deployment.

* src - Source code of the AI engine
* tests - Unity, integration, etc
* protos - GRPC API for all VA services
* dependencies - All dockerfiles used to build basic images for the VA services
    
Other repositories besides this one are used to build the images required to deploy VA.

* ConceptNet server - a standalone server which allows queries for terms in ConceptNet 5.
* SUMO server - a standalone server which allows queries in the ontologies of SUMO database.
* Android app - not actually required to build VA. This repository have the source code for the Android app which is a front-end for VA.

## 2. Getting started

This repository contains a setup.sh script which is used to build and deploy the virtual assistant in all of its completude. You should have [docker](docker-site) installed in order to proceed.

### Fresh start - Build and deploy a fresh virtual assistant program and environment from scratch.

Just run the following command and the setup script will build and deploy all the necessary components for you.

```
./setup.sh all
```

### Speak with the virtual assistant through command line bypassing the session manager

In order to have a conversation, through command line, with the virtual assistant using the deployed solution do the following.

1) run docker exec to enter the virtual assistant container.

```
docker exec -it va_ai_server_container bash
```

2) enter the bin folder right after entering its container.

```
cd bin
```

3) run the client to start a session with the start_session command.

```
./client sync VA start_session
```

4) it will return the number 3 which represents the oppened session, use this number to send phrases to the assistant using the client executable.

```
./client sync VA utterance 3 "Hello assistant, could you recommend a good restaurant for ana and I for this friday evening?"
```

5) the assistant will evaluate the sentence and it should respond the following.

```
Any preferences on cuisine ?
```

You can keep up the conversation after this point.

### Setup script

The setup script provides the following commands:

1) build - This command build a specific component of the virtual assistant. The available components are described as follows.
    * dep_grpc - Builds a basic cpp grpc image.
        ```
        usage: ./setup.sh build dep_grpc
        ```
    * dep_opencog - Builds a basic opencog ready image.
        ```
        usage: ./setup.sh build dep_opencog
        ```
    * ai - Builds all the virtual assistant main images.
        ```
        usage: ./setup.sh build ai
        ```
    * conceptnet - Builds the conceptnet server image.
        ```
        usage: ./setup.sh build conceptnet
        ```
    * sumo - Builds the sumo server image.
        ```
        usage: ./setup.sh build sumo
        ```
    * session-manager - Builds the session manager image.
        ```
        usage: ./setup.sh build session-manager
        ```
    * conceptnet-database - Builds the conceptnet database to be used by the    conceptnet server.
        ```
        usage: ./setup.sh build conceptnet-database
        ```
2) deploy - This command deploy a specific component of the virtual assistant. The available components are described as follows.
    * ai - deploy the Relex and the virtual assistant containers.
        ```
        usage: ./setup.sh deploy ai
        ```
    * conceptnet - deploy the conceptnet 5 server container.
        ```
        usage: ./setup.sh deploy conceptnet
        ```
    * sumo - deploy the sumo server container.
        ```
        usage: ./setup.sh deploy sumo
        ```
    * session-manager - deploy the session manager container.
        ```
        usage: ./setup.sh deploy session-manager
        ```
3) build-all - This command builds all the virtual assistant components.
    ```
    usage: ./setup.sh build-all
    ```
4) deploy-all - This command deploys all the virtual assistant components.
    ```
    usage: ./setup.sh deploy-all
    ```
5) all - This command builds and deploy all the necessary containers and dependencies.
    ```
    usage: ./setup.sh all
    ```

## 3. Architecture and design notes

![vacomponents](assets/VAComponents.jpg 'VA components')

Virtual Assistant may have many different front-ends. Currently we have only an
[Android app][app-repo] which is a simple [Unity3D][unity-site] application
with a 3D avatar and STT/TTS capabilities.

[Session Manager](./session-manager/README.MD) is the back-end component that
interfaces with the front-ends.  It provides user authentication and process
all front-end requests, routing them to the proper component and managing
respective responses. Front-end uses GRPC to call Session Manager services
according to this [protobuf file](./protos/SessionManager.proto).

### 3.1. Sensory information

Communication between the front-end and the Session manager is basically
sensory information captured by the former. The environment surrounding VA (both
the physical environment around the user and the logical environment where VA
is deployed) is observed by device listeners which can either be
activated explicitly by the user (e.g. STT or a text entry in the keyboard
explicitly directed to VA) or can be active all the time, listening and
capturing information (e.g. a daemon checking for new files added to some file
system by other apps).

Listeners are typically part of the front-end (e.g. an Android app, desktop
application, etc) so their actual integration in the VA architecture will
depend on the target platform VA will be deployed (e.g. Android, Linux station
etc). In addition to this, they may behave differently in mobile, desktop, etc.
E.g. when VA is running in a desktop, device listeners can process input and
generate sensory information directly but since this computation may require
the execution of AI algorithms, in a mobile scenario we may need to split
device listeners in two components, one running in the phone and sending raw
information to the other, running in a server, which will actually generate the
sensory information.

Currently, we have two listeners in the Android app:

1. Microphone - we listen to the microphone to catch user's speeches which are sent to a STT
2. GPS - current user's location is tracked

A listener decodes raw information captured by the device and turn it into
sensory information, which is the basic information unit used by VA to monitor
and understand the environment.

The same listener can potentially  generate one or more sensory information.
For instance, a microphone listener may be able to apply STT to detect user's
utterance as well as an emotion detection algorithm to identify emotion in its
voice. Similarly there could be more than one listener capable of generating
the same sensory information. For instance, user's utterance can be captured
either by microphone or keyboard listener.

### 3.2. Context enrichment algorithms

For each sensory information received by the Session Manager, there may be
zero, one or more context enrichment servers which are called to generate more
information based on the one received. This extra information is then sent to
OpenCog. Communication between the Session Manager and such servers is also
based in GRPC.

Context enrichment is asynchronous. It means that upon receiving a sensory
information, the Session Manager forward it immediately to OpenCog while
issuing requests to the context enrichment servers. As soon as they provide
responses, they are forwarded to OpenCog as well. Note that, potentially, the
Session Manager could send many other sensory information to OpenCog before
getting and forwarding responses from a previous request made to a context
enrichment server.

Currently we have three context enrichment servers:

1. Restaurant information
2. Named entity recognition
3. Sentiment analysis

[Restaurant information](./restaurant-info-server/README.md) is called to keep
OpenCog up to date with information regarding restaurants in the surroundings of
user's current location. This is implemented as an enrichment of the
`geolocation` information which is a basic sensory information.

[Named entity recognition][ner-service] and [Sentiment analysis][sa-service]
are SingularityNET services. The former identifies named entities (e.g. Anna,
George Bush, Apple, USA, United Nations etc) and the latter provides an
estimate of emotional bias in user's sentences.

### 3.3. VA engine - OpenCog

This component is the actual decision making algorithm. It's an OpenCog
instance running [GHOST][ghost-readme] which controls the dialogue flow as well
as the execution of user requested actions.

VA is not a chatbot. It's an assistant which uses dialogues to interact with
the user and understand which actions are being requested and which
information (if any) should be used to help executing them.

To understand user's intents and extract relevant information from the user
utterances, we may follow two different approaches in the GHOST rules (read
[GHOST documentation][ghost-readme] to understand how GHOST rules work)

1. Make the patterns of the rules as specific as possible, kind of like doing
regex, in order to capture the information we want, e.g. `(recommend a good restaurant
for [$var_who] near [$var_where] at [$var_time])`, then pass those information to the
corresponding function, e.g. `recommend_restaurant($var_who, $var_where,
$var_time)`. This is the approach used by other virtual agents like Siri, Alexa
and others.
2. Another way is quite the opposite, by making the rules more abstract, e.g.
`(recommend * restaurant)`, then let the function do all the heavy work, e.g.
`recommend_restaurant()` will look for the useful info from the most recent user
input.

There are pros and cons in the two approaches:

The first one is really annoying as there could be so many ways of saying the
same thing, meaning that we'll have to prepare many rules with different
patterns to handle a particular type of utterance, yet we may still miss some
and the extracted info may still be noisy, but the functions can be kept
relatively simple.

The second approach hides all the complexities in the functions, and it relies
more heavily on language understanding, as the functions have to find all the
info from the R2L/RelEx outputs etc. This could also be annoying given that the
current form of our NLP pipeline is not that great and reliable, and it could
be difficult especially when the input utterance gets a bit more lengthy and
complicated.

Current implementation follows 2. but with smaller functions and a clear
separation between finding out what user said and the control of the dialogue
flow.

### 3.4. Implemented VA engine (using GHOST rules)

First of all, a couple of assumptions.

* Sessions are small and objective. The user started the session with VA to ask
for a restaurant suggestion and as soon as user have all the information he
needs regarding that suggestion the session finishes.
* We keep all RelEx/R2L information of current session

Define functions to evaluate predicates used to control the execution flow of
this skill (the skill is : "Recommend restaurant")

```
P1: user_requested_restaurant_recomendation() {
    // some heuristics like using PatternMiner to look for RelEx links like
    And
        EvaluationLink
            DefinedLinguisticRelationshipNode "_subj"
            ListLink
                WordInstanceNode $1
                WordInstanceNode $2
        EvaluationLink
            DefinedLinguisticRelationshipNode "_obj"
            ListLink
                WordInstanceNode $1
                WordInstanceNode $3
        ReferenceLink
            WordInstanceNode $1
            WordNode "recommend"
        ReferenceLink
            WordInstanceNode $2
            WordNode "you"
        ReferenceLink
            WordInstanceNode $3
            WordNode "restaurant"
}
```

Actually we may use SUMO and/or ConceptNet to improve the query to accept
synonyms etc. Anyway we would have similar queries to compute a set of
predicates like

```
P2: user_mentioned_cuisine()
P3: user_mentioned_time()
P4: user_mentioned_location()
... etc
```

Once all useful predicates are defined. Define rules to execute the skill

```
R1: if P1() and P2() and P3() {
    // Assumes that only "cuisine" and "time" are required. Other info are optional.
    // Get cuisine and time using the same RelEx info used to evaluate the predicate.
    // Get any other optional info
    // Execute the skill
}

R2: if P1() and not P2() {
    // First, try to infer cuisine. This may require additional predicates and rules
    // If couldn't infer cuisine, ask it explicitly to the user
}

R3: if P1() and not P3() {
    // Ask the user the preferred time.
}

... etc
```

Thus the idea is breaking the skill into predicates evaluation and rules execution.

Predicates can be "nested" to avoid useless evaluations. I mean e.g. we only
need to evaluate P2, P3 etc if P1 is TRUE.

Rules can be breakdown into smaller sub-rules like in a regular programming language.

This approach have the potential to become a mess so we need to organize each
skill separately (e.g. in separate folders/files)  so one skill's mess don't
interfere with other's. So we'd able to select which skills to load for each
VA. Developing a new skill would mean writing a new set of predicates
definitions and a new set of rules. Another interesting aspect of having such
separation is the hability to reuse predicates like `user_mentioned_time()` or
`user_mentioned_location()` in many different skills.

### 3.5. NLP pipeline

Before passing user's utterances to GHOST, each sentence is passed through a
NLP pipeline to create the relevant nodes and links in the AtomSpace.

![nlp](assets/NLP.jpg 'NLP pipeline')

All these atoms are supposed to be created in the short-term memory so they are
supposed to be forgotten when the session ends (a session is an interaction cycle
where the user makes a request, the VA gathers relevant information and then
execute one or more actions to fulfill user's request). The forgetting mechanism
(actually the whole short-term memory component) is not implemented yet. This
is detailed in the section "Moving Forward" below.

## 4. Moving forward

In this section we list some of the components/features that are still missing
in VA.

### 4.1. Short-term and long-term memories

The set of all sensory information constitutes the context which VA uses to
take its decisions and execute its actions. Context is the set of links that
represents VA's knowledge about the environment. Context is constantly being
fed by new sensory information so it's important to have a policy to discard
old/irrelevant data. This is necessary for two reasons.

* Old sensory information may be deprecated and act as noise in the
decision-making algorithm which controls VA's behavior.
* It's important to keep all relevant sensory information in RAM to make the
decision-making algorithm run faster.

To address the problem of discarding old/irrelevant sensory information we
split context in short-term and long-term context.

Short-term context is a short-term memory of sensory information. Every new
information is fed into the short-term context first, tagged with current
timestamp, and expires according to three expiration policies:

1. Short-term context reached a predefined limit size
1. Information reached a default expiration threshold time
1. The interaction session (between VA and user) finished

Different sensory information may have different thresholds in above policies
meaning that some sensory information may rest longer than others in the
short-term context.

There's no criterion based in importance or relevance to keep/remove
information from short-term context. Whenever a piece of information become
relevant (e.g. by being used to execute a skill or answer a user's question)
it's moved from short-term context into the long-term context.

Long-term context keeps a history of all past interactions between VA and the
user, holding information of VA's decisions, executed actions (and their
respective parameters), dialogues, etc. Long-term context is also initialized
with any "global knowledge" common to all users. Contents of long-term context
are persisted to be used in future interaction sessions

Context is stored in an AtomSpace which is initialized with the contents of
long-term context previously persisted in a DB. Long-term context is initially
created using a global knowledge base common to all  assistants. A short-term
memory (STM) need to be implemented to keep track of new sensory information
being fed by device listeners and context enrichment algorithms.  Any atoms fed
into STM which are not used to take decisions, answer questions or execute
actions are forgotten. The remaining atoms become part of the long-term context
and continue living in the AtomSpace (and are persisted in the DB) so long-term
context grows as user interacts with the VA.

User's long-term contexts can be uploaded to the common knowledge base.
Uploaded information can be used by some off-line reasoning process to create a
kind of common-sense knowledge base that could be sent back to particular
user's contexts to enhance its basic knowledge. ** This particular feature can
be a very tricky authorization and privacy issue. This is less of a concern in
a shared team that expect their interactions to not be entirely private, but
for any consumer product we shouldn't underestimate the effort in this work. **

### 4.2. Episodic memory

Episodic memory is part of the long-term memory in the sense that it's
persisted and used across many sessions of a given user. It's supposed to keep
track of relevant events associated with a certain point in time and/or space.

### 4.3. Android app

1. Implement camera listener (photo and video)
1. Integration with device's contacts/storage/media/file system
1. Integration with device's notification system
1. Integration with other apps (e-mail, SMS, etc)
1. Eye-tracking
1. Keyphrase recognition
1. Fancier (artistic) avatar characters
1. Improve avatar animation (using motion capture techniques like e.g.
Ubisoft's and Blizzard's characters)
1. Improve avatar lipsync (e.g. by improve phoneme detection)
1. Evaluate use cases where full-body animation can be used e.g. the avatar
could help an insurance customer showing what are the better angles to take
photos from this car or from an crash scene.

