import os
import json
from dotenv import load_dotenv
from langchain_community.agent_toolkits.sql.base import create_sql_agent, SQLDatabaseToolkit
from langchain_community.utilities import SQLDatabase
from langchain_groq import ChatGroq
from langchain.agents import AgentType

class AnalyticsAgent:
    def __init__(self):
        load_dotenv()
        api = os.getenv("GROQ_API_KEY")
        mysql_uri = os.getenv("MYSQL_URI")
        
        self.llm = ChatGroq(
            model_name="llama3-70b-8192",
            api_key=api,
            temperature=0,
            max_tokens=1000,
            model_kwargs={"top_p": 0.7}
        )
        self.db = SQLDatabase.from_uri(mysql_uri)
        self.toolkit = SQLDatabaseToolkit(db=self.db, llm=self.llm)
        self.sql_agent = create_sql_agent(
            llm=self.llm,
            toolkit=self.toolkit,
            agent_type=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
            verbose=True
        )
        
        # Predefined SQL query templates for common questions
        self.query_templates = {
            # "top_selling_packages": "WITH RankedPackages AS (SELECT package_name, SUM(price_per_night) AS total_price, RANK() OVER (ORDER BY SUM(price_per_night) DESC) AS rnk FROM master_package_booking GROUP BY package_name) SELECT package_name, total_price FROM RankedPackages WHERE rnk <= 3 UNION ALL SELECT 'Other Packages', SUM(total_price) FROM RankedPackages WHERE rnk > 3;",
            "revenue_figure": "SELECT month, SUM(master_package_revenue) AS master_package_revenue, SUM(master_event_revenue) AS master_event_revenue, SUM(master_package_revenue + master_event_revenue) AS total_revenue FROM (SELECT DATE_FORMAT(itinerary_date, '%Y-%m') AS month, SUM(price_per_night) AS master_package_revenue, 0 AS master_event_revenue FROM master_package_booking WHERE booking_status = 'Confirmed' AND package_name IS NOT NULL AND itinerary_date BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 11 MONTH), '%Y-%m-01') AND LAST_DAY(CURRENT_DATE) GROUP BY DATE_FORMAT(itinerary_date, '%Y-%m') UNION ALL SELECT DATE_FORMAT(itinerary_date, '%Y-%m') AS month, 0 AS master_package_revenue, SUM(price_per_night) AS master_event_revenue FROM master_event_booking WHERE booking_status IN ('Confirmed', 'Completed') AND itinerary_date BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 11 MONTH), '%Y-%m-01') AND LAST_DAY(CURRENT_DATE) GROUP BY DATE_FORMAT(itinerary_date, '%Y-%m')) AS combined_data GROUP BY month ORDER BY month;",
            # "top_selling_events": "SELECT e.event_name, COUNT(eb.event_booking_id) as num_bookings FROM event e JOIN event_booking eb ON e.event_id = eb.event_reservation_id GROUP BY e.event_name ORDER BY num_bookings DESC LIMIT 10;",
            "customer_insights": "SELECT (SELECT COUNT(*) FROM customer) AS total_customers, COUNT(CASE WHEN booking_count = 1 THEN 1 END) AS new_customers, COUNT(CASE WHEN booking_count > 1 THEN 1 END) AS returning_customers FROM (SELECT customer_id, COUNT(*) AS booking_count FROM (SELECT customer_id FROM master_event_booking UNION ALL SELECT customer_id FROM master_package_booking) AS combined_bookings WHERE customer_id IS NOT NULL GROUP BY customer_id) AS booking_summary;"
       }

    def get_query_hint(self, user_query: str) -> str:
        # Simple keyword matching (can be expanded using NLP if needed)
        if "packages" in user_query.lower():
            return self.query_templates.get("top_selling_packages")
        elif "revenue" in user_query.lower():
            return self.query_templates.get("revenue_figure")
        elif "events" in user_query.lower():
            return self.query_templates.get("top_selling_events")
        elif "customer" in user_query.lower():
            return self.query_templates.get("customer_insights")
        return None

    def run_query_as_it_is(self, user_query: str) -> str:
        prompt = (
            "You are an expert SQL data analyst. Given a user's request, generate an optimized SQL query "
            "to retrieve insights from the databases  search from master booking events and master booking packages. Return results in a clear, structured JSON format. "
            "Focus on key insights and meaningful data presentation."
        )
        
        # Provide a query hint if available
        query_hint = self.get_query_hint(user_query)
        if query_hint:
            prompt += f"\n\nHere is a helpful SQL query template for similar requests: {query_hint}"
        
        try:
            response = self.sql_agent.invoke(f"{prompt}\n\nUser Query: {user_query}")
            return response.get('output', str(response))
        except Exception as e:
            return json.dumps({"error": str(e), "query": user_query}, indent=2)

if __name__ == "__main__":
    agent = AnalyticsAgent()
    query = "What are the most book hotels?"
    print(agent.run_query_as_it_is(query))
