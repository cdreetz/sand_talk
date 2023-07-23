from flask import Flask, request, jsonify
import openai
import os
from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY')

openai.api_key = OPENAI_API_KEY

app = Flask(__name__)

@app.route('/get_gpt_response', methods=['POST'])
def get_gpt_response():
    data = request.json
    user_input = data.get('input')

    # Create a conversation with the chat model
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",  # use an appropriate model
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant."
            },
            {
                "role": "user",
                "content": user_input
            }
        ]
    )

    # Get the assistant's reply
    gpt_response = response['choices'][0]['message']['content']

    return jsonify(output=gpt_response)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000)

