import streamlit as st
import requests
import re
import json
import pandas as pd
import matplotlib.pyplot as plt

# FastAPI chatbot endpoint URL
API_URL = "http://localhost:8000/chat"

st.set_page_config(page_title="Chatbot Interface with Dynamic Pie Charts", layout="wide")
st.title("Chatbot Interface with Dynamic Pie Charts")
st.markdown("Enter your query below to interact with the chatbot. If analytics data is present in the response, a pie chart will be generated automatically.")

# Initialize session state for conversation history
if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

# Function to send user message to chatbot API
def send_message_to_chatbot(user_msg: str):
    payload = {"message": user_msg}
    try:
        response = requests.post(API_URL, json=payload)
        if response.status_code == 200:
            data = response.json()
            return data.get("response", ""), data.get("analytics_json", None)
        else:
            return f"API error: {response.status_code}", None
    except Exception as e:
        return f"Error contacting API: {e}", None

# Function to extract JSON from text
def extract_json_from_text(text: str):
    pattern = r"```(.*?)```"
    match = re.search(pattern, text, re.DOTALL)
    if match:
        json_str = match.group(1).strip()
        try:
            return json.loads(json_str)
        except Exception as e:
            st.error(f"Error parsing extracted JSON: {e}")
            return None
    return None

# Function to auto-detect columns for pie chart
def auto_detect_columns(dataset: list):
    if not dataset:
        return None, None
    sample = dataset[0]
    name_col = None
    num_col = None
    for key in sample.keys():
        if "price" in key.lower() or "booking" in key.lower():
            num_col = key
        if "name" in key.lower():
            name_col = key
    return name_col, num_col

# Chat input
user_input = st.chat_input("You:")
if user_input:
    # Display user message
    with st.chat_message("user"):
        st.write(user_input)
    # Send user message to chatbot
    bot_response, analytics = send_message_to_chatbot(user_input)
    # Display chatbot response
    with st.chat_message("assistant"):
        st.write(bot_response)
        # Check for embedded JSON in the response
        extracted_json = extract_json_from_text(bot_response)
        if extracted_json:
            raw_data = extracted_json.get("raw_data", None)
            dataset = None
            if isinstance(raw_data, dict):
                keys = list(raw_data.keys())
                if keys:
                    selected_key = st.selectbox("Select dataset for graph", keys)
                    dataset = raw_data.get(selected_key, [])
            elif isinstance(raw_data, list):
                dataset = raw_data
            else:
                dataset = []
            if dataset:
                name_col, num_col = auto_detect_columns(dataset)
                if name_col and num_col:
                    df = pd.DataFrame(dataset)
                    st.markdown("**Generated Pie Chart:**")
                    fig, ax = plt.subplots()
                    ax.pie(df[num_col], labels=df[name_col], autopct='%1.1f%%', startangle=90)
                    ax.axis('equal')
                    st.pyplot(fig)
                else:
                    st.info("Could not auto-detect columns for graph generation.")
            else:
                st.info("No dataset available for graph generation.")
        elif analytics:
            # Fallback for separate analytics data
            dataset = analytics
            if isinstance(dataset, dict):
                keys = list(dataset.keys())
                if keys:
                    selected_key = st.selectbox("Select dataset for graph", keys)
                    dataset = dataset.get(selected_key, [])
            elif not isinstance(dataset, list):
                dataset = []
            if dataset:
                name_col, num_col = auto_detect_columns(dataset)
                if name_col and num_col:
                    df = pd.DataFrame(dataset)
                    st.markdown("**Generated Pie Chart:**")
                    fig, ax = plt.subplots()
                    ax.pie(df[num_col], labels=df[name_col], autopct='%1.1f%%', startangle=90)
                    ax.axis('equal')
                    st.pyplot(fig)
                else:
                    st.info("Could not auto-detect columns for graph generation.")

    # Append user and chatbot messages to chat history
    st.session_state.chat_history.append(("user", user_input))
    st.session_state.chat_history.append(("assistant", bot_response))

# Display chat history
for role, msg in st.session_state.chat_history:
    with st.chat_message(role):
        st.write(msg)
