import os
import json
from dotenv import load_dotenv
from langgraph.graph import StateGraph, MessagesState, START, END
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.checkpoint.memory import MemorySaver
from langgraph.types import Command
from langchain_groq import ChatGroq
from .Agents.AnalyticsAgent import AnalyticsAgent
from .Agents.ItineraryPlanningAgent import ItineraryPlanningAgent

load_dotenv()
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise EnvironmentError("GROQ_API_KEY not found in environment variables.")

class Chatbot:
    def __init__(self):
        # Reuse a single LLM instance for all LLM calls.
        self.llm = ChatGroq(model_name="llama3-70b-8192", api_key=GROQ_API_KEY)
        self.analytics_agent = AnalyticsAgent()
        self.itinerary_agent = ItineraryPlanningAgent()
        self.thread_id = "chat_1"

    def get_last_message(self, state) -> str:
        messages = state.get("messages", [])
        return messages[-1].content if messages else ""

    # Intent detection node.
    def detect_intent(self, state: MessagesState):
        user_input = self.get_last_message(state)
        prompt = (
            "Determine the intent of the following query. "
            "Respond exactly with 'analytics' if the query is about data analysis For Example: hotel related analytics, most book hotels, top selling packages, top selling events, most book drivers, customer insights, revenue figures etc, "
            "'itinerary' if it is about travel planning, "
            "or 'unknown' if neither.\n"
            f"User Query: {user_input}"
        )
        response = self.llm.invoke([HumanMessage(content=prompt)])
        state["intent"] = response.content.strip().lower()
        return state

    # Process JSON data using LLM to generate a detailed and polite explanation.
    def analytics_process_json(self, json_data: str) -> dict:
        prompt = (
    "As a customer service chatbot assistant, please transform the following JSON data into a human-readable format. write in a single line and after every word add a space. "
    "Focus on presenting the information clearly and concisely, ensuring all essential details are easily understood. "
    "Return a JSON object with two keys: "
    "'detailed_response': (containing the human-readable explanation), and "
    "'raw_data': (containing the original JSON data).\n\n"
    f"JSON Data: {json_data}"
)


        response = self.llm.invoke([HumanMessage(content=prompt)])
        try:
            processed = json.loads(response.content)
        except Exception:
            processed = {"detailed_response": response.content, "raw_data": json_data}
        return processed
    
    def itinerary_process_json(self, text_response: str) -> dict:
        try:
            processed = json.loads(text_response)
        except Exception:
            processed = {"itinerary": text_response, "raw_data": ""}
        return processed

    # Analytics Agent node: Process the JSON result and return both a detailed explanation and raw JSON.
    def analytics_agent_node(self, state: MessagesState):
        query = self.get_last_message(state)
        result_json = self.analytics_agent.run_query_as_it_is(query)
        processed = self.analytics_process_json(result_json)
        human_msg = (
            "[Analytics Agent]:\n"
            "Detailed Information:\n" + processed.get("detailed_response", "") + "\n\n"
            "For more detailed data, please refer to the attached JSON."
        )
        return {"messages": [SystemMessage(content=human_msg)],
                "json_data": processed.get("raw_data")}

    # Itinerary Agent node.
    def itinerary_agent_node(self, state: MessagesState):
        query = self.get_last_message(state)
        result = self.itinerary_agent.run_query(query)
        reply = f"[Itinerary Agent]: {result}"
        return {"messages": [SystemMessage(content=reply)]}

    # Fallback node.
    def direct_answer(self, state: MessagesState):
        reply = "I'm a Chatbot Assistant how can I help you?"
        
        return {"messages": [SystemMessage(content=reply)]}

    # Routing function based on detected intent.
    def route_intent(self, state: MessagesState):
        intent = state.get("intent", "unknown")
        if intent == "analytics":
            return "analytics_agent"
        elif intent == "itinerary":
            return "itinerary_agent"
        else:
            return "direct_answer"

    # Build the multi-agent workflow.
    def build_workflow(self):
        workflow = StateGraph(MessagesState)
        workflow.add_node("detect_intent", self.detect_intent)
        workflow.add_node("analytics_agent", self.analytics_agent_node)
        workflow.add_node("itinerary_agent", self.itinerary_agent_node)
        workflow.add_node("direct_answer", self.direct_answer)
        # Start directly with detect_intent.
        workflow.add_edge(START, "detect_intent")
        workflow.add_conditional_edges("detect_intent", self.route_intent)
        workflow.add_edge("analytics_agent", END)
        workflow.add_edge("itinerary_agent", END)
        workflow.add_edge("direct_answer", END)
        memory = MemorySaver()
        app = workflow.compile(checkpointer=memory)
        config = {"configurable": {"thread_id": self.thread_id}}
        return app, config

    # Main run loop.
    def run(self):
        app, config = self.build_workflow()
        print("Enter your query (type 'exit' to quit):")
        while True:
            user_input = input("You: ")
            if user_input.lower() == "exit":
                print("Exiting chatbot. Goodbye!")
                break
            state = {"messages": [HumanMessage(content=user_input)]}
            response = app.invoke(state, config=config)
            final_msgs = response.get("messages", [])
            print("Assistant:", final_msgs[-1].content if final_msgs else "No answer returned.")
            # For the frontend: print the raw JSON data if available.
            if "json_data" in response:
                print("Raw JSON Data:", response["json_data"])

if __name__ == "__main__":
    chatbot = Chatbot()
    chatbot.run()
