import os
import json
import re
from dotenv import load_dotenv
from langchain_community.agent_toolkits.sql.base import create_sql_agent, SQLDatabaseToolkit
from langchain_community.utilities import SQLDatabase
from langchain_groq import ChatGroq
from langchain.agents import AgentType

class ItineraryPlanningAgent:
    def __init__(self):
        load_dotenv()
        api = os.getenv("GROQ_API_KEY")
        mysql_uri = os.getenv("MYSQL_URI")
        if not api or not mysql_uri:
            raise ValueError("Missing environment variables: GROQ_API_KEY or MYSQL_URI")
        
        # Initialize LLM for detailed itineraries.
        self.llm = ChatGroq(
            model_name="llama3-70b-8192",
            api_key=api,
            temperature=0.2,
            max_tokens=1024,
            model_kwargs={"top_p": 0.8, "presence_penalty": 0.6}
        )
        
        # Set up the SQL database connection and toolkit.
        self.db = SQLDatabase.from_uri(mysql_uri)
        self.toolkit = SQLDatabaseToolkit(db=self.db, llm=self.llm)
        
        # System prompt instructing the agent on the desired output format.
        self.system_message = (
            "You are a specialized travel planning assistant that creates detailed itineraries. "
            "Query the database for valid locations, hotels, activities, and drivers and create a day-by-day itinerary. "
            "Return the result as a JSON object with two keys: "
            "'itinerary': an object containing 'title' (a summary) and 'days' (an array of objects, each with keys 'day' and 'activities'), "
            "and 'raw_data': the raw SQL query results."
        )
        
        self.sql_agent = create_sql_agent(
            llm=self.llm,
            toolkit=self.toolkit,
            agent_type=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
            verbose=True
        )

    def process_json(self, text_response: str) -> dict:
        """Attempt to parse the text response as JSON; if it fails, wrap the text in a JSON object."""
        try:
            return json.loads(text_response)
        except Exception:
            return {
                "itinerary": {"title": text_response, "days": []},
                "raw_data": text_response
            }

    def run_query(self, user_query: str) -> dict:
        """Generate a detailed travel itinerary based on the user's query."""
        location_info = self._extract_location_info(user_query)
        prompt = f"""
{self.system_message}

TASK: Generate a detailed travel itinerary with the following specifications:
- Destination: {location_info.get('destination', 'unknown')}
- Starting location: {location_info.get('start_location', 'unknown')}
- Duration: {location_info.get('duration', '3 days')}

Your response must be a valid JSON object with:
- "itinerary": an object with:
    - "title": a string summarizing the overall itinerary.
    - "days": an array of objects, each with:
         - "day": a string (e.g., "Day 1").
         - "activities": a detailed description of that day's plan.
- "raw_data": the raw data from the database.
Only include recommendations that exist in the database.
"""
        response = self.sql_agent.invoke(prompt)
        return self.process_json(response.get("output", str(response)))

    def _extract_location_info(self, query: str) -> dict:
        """Extract destination, starting location, and duration using simple regex patterns."""
        info = {"destination": "unknown", "start_location": "unknown", "duration": "3 days"}
        query_lower = query.lower()
        # Extract destination (e.g., "to Dharamshala")
        dest_match = re.search(r'\bto\s+([a-z\s]+)', query_lower)
        if dest_match:
            info["destination"] = dest_match.group(1).strip().split()[0]
        # Extract starting location (e.g., "starting location is Guwahati" or "from Guwahati")
        start_match = re.search(r'\b(?:starting location is|from)\s+([a-z\s]+)', query_lower)
        if start_match:
            info["start_location"] = start_match.group(1).strip().split()[0]
        # Extract duration (e.g., "for 3 days")
        duration_match = re.search(r'\bfor\s+(\d+)\s*day', query_lower)
        if duration_match:
            info["duration"] = f"{duration_match.group(1)} days"
        return info

if __name__ == "__main__":
    agent = ItineraryPlanningAgent()
    print("Welcome to the Travel Itinerary Planner!")
    print("Example query: 'Generate a planned itinerary for 3 days to Dharamshala, starting location is Guwahati'")
    
    while True:
        user_input = input("\nEnter your query (or type 'exit' to quit): ").strip()
        if user_input.lower() == "exit":
            print("Exiting the system. Goodbye!")
            break
        try:
            result = agent.run_query(user_input)
            print("\n----- Your Personalized Itinerary -----")
            print(json.dumps(result, indent=2))
            print("---------------------------------------")
        except Exception as e:
            print(f"Error: {str(e)}")
