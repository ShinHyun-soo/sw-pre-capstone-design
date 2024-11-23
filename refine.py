import json
import os
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize OpenAI client
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("API key is not set. Make sure 'OPENAI_API_KEY' is in your .env file.")
client = OpenAI(api_key=api_key)


# Function to generate prompt
def generate_prompt(question, answer):
    prompt = f"""
    Please analyze the question and answer to identify the intent elements using the provided traits, and return the result strictly in JSON format.

    ### 5 Intent Element Traits:
    - **Personality characteristic**: Identifies personality or disposition.
    - **Philosophy characteristic**: Reveals beliefs or ideas considered important.
    - **Self-improvement characteristic**: Indicates efforts for personal growth.
    - **Insight characteristic**: Reflects thoughts on situations or solutions.
    - **Expertise characteristic**: Shows knowledge of specific concepts or occupational expertise.
    - **Other**: Anything not included above.

    ### Input:
    Question: {question}
    Answer: {answer}

    ### Output:
    {{
        "question_intent": "string",
        "answer_intents": [
            {{"intent": "string", "justification": "string"}}
        ]
    }}
    """
    return prompt

def generate_prompt(question, answer):
    prompt = f"""
    Please analyze the question and answer to identify the intent elements using the provided traits, and return the result strictly in JSON format.

    ### 5 Intent Element Traits:
    - **Personality characteristic**: Identifies personality or disposition.
    - **Philosophy characteristic**: Reveals beliefs or ideas considered important.
    - **Self-improvement characteristic**: Indicates efforts for personal growth.
    - **Insight characteristic**: Reflects thoughts on situations or solutions.
    - **Expertise characteristic**: Shows knowledge of specific concepts or occupational expertise.
    - **Other**: Anything not included above.

    ### Input:
    Question: {question}
    Answer: {answer}

    ### Output:
    {{
        "question_intent": "string",
        "answer_intents": [
            {{"intent": "string", "justification": "string"}}
        ]
    }}
    """
    return prompt

def evaluate_prompt(question, answer):
    prompt = f"""
    "Using the characteristics of appropriate and inappropriate responses below, please evaluate the interviewee’s interview demeanor and the quality of their responses as evidenced by the given question and answer information to determine the appropriateness of the answer. Please circle an O for appropriate and an X for inappropriate. And also include 3–4 lines of your analysis."

    "###"
    "1. Characteristics of an appropriate answer:
        Clear and specific: The answer is direct and clear, making it easy for the interviewer to understand.
        Relevant: The answer stays on topic and directly addresses the question, without including unnecessary information.
        Based on real experience: The response is grounded in actual experience or concrete examples, adding credibility.
        Confident yet humble: The answer is delivered with confidence, but not arrogance, and conveys a clear, assured tone.
        Concise and respectful: The response is brief and to the point, avoiding overly lengthy explanations, while maintaining politeness."
    "2. Characteristics of an inappropriate answer:
        Unclear or vague: The answer lacks clarity or is too vague, making it difficult for the interviewer to understand.
        Includes irrelevant information: The answer diverges from the question and introduces unrelated topics.
        Lacks real-life examples: The answer is theoretical, hypothetical, or overly general without any actual examples or concrete experience.
        Lack of confidence: The answer is unsure or hesitant, possibly lacking conviction or appearing unprepared.
        Unnecessarily long-winded: The response is overly detailed or lengthy, including irrelevant information that distracts from the main points."
    "3. Expertise essential considerations:
        Knowledge and experience relevant to the job: The answer demonstrates a solid understanding of the skills and experiences required for the job.
        Awareness of industry trends: The response shows an understanding of the latest trends, challenges, or developments within the industry related to the job.
        Problem-solving ability: The ability to approach and solve job-related challenges is a key indicator of expertise.
        Communication skills: Being able to clearly communicate complex ideas or issues in a way that’s easy for others to understand is an essential part of expertise.
        Teamwork and collaboration: In modern roles, the ability to work effectively within a team is often just as important as individual skills, so examples of collaboration and team experience are important."
    "###"
    
    "###"
    "<<Interview question and answers with answer breakdown>>"
    "Question: {question}"
    "Answer: {answer}"
    "###"
    """
    return prompt

# Function to refine a single dataset
def refine_dataset_with_llm(data):
    try:
        # Extract question and answer
        question_text = data["dataSet"]["question"]["raw"]["text"]
        answer_text = data["dataSet"]["answer"]["raw"]["text"]

        # Generate prompt
        prompt = generate_prompt(question_text, answer_text)

        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7
        )

        # Parse and clean response
        raw_content = response.choices[0].message.content.strip()
        print("Raw API Response:", raw_content)

        try:
            categorized_intents = json.loads(raw_content)
        except json.JSONDecodeError as e:
            print(f"JSON Parsing Error: {e}")
            return {
                "question": question_text,
                "answer": answer_text,
                "categorized_intents": {
                    "error": "Failed to parse API response",
                    "raw_response": raw_content
                }
            }

        # Return refined entry
        return {
            "question": question_text,
            "answer": answer_text,
            "categorized_intents": categorized_intents
        }

    except Exception as e:
        print(f"Error processing dataset: {str(e)}")
        return {
            "error": str(e)
        }


# Main execution to process multiple files
def process_all_datasets(input_dir, output_file, max_files=2000):
    refined_data = []

    # Iterate over all JSON files in the directory, limiting to `max_files` files
    files_processed = 0
    for filename in os.listdir(input_dir):
        if filename.endswith(".json"):
            file_path = os.path.join(input_dir, filename)
            print(f"Processing file: {file_path}")

            try:
                with open(file_path, 'r', encoding='utf-8') as file:
                    data = json.load(file)

                # Process and refine data
                refined_entry = refine_dataset_with_llm(data)
                refined_data.append(refined_entry)

                files_processed += 1
                if files_processed >= max_files:
                    print(f"Reached maximum file limit of {max_files}.")
                    break

            except Exception as e:
                print(f"Error reading or processing file {filename}: {str(e)}")

    # Save all refined data to the output file
    try:
        with open(output_file, 'w', encoding='utf-8') as file:
            json.dump(refined_data, file, ensure_ascii=False, indent=4)
        print(f"All data has been successfully refined and saved to {output_file}.")
    except Exception as e:
        print(f"Error saving refined data: {str(e)}")


# Run the processing function
if __name__ == "__main__":
    input_directory = './data/'
    output_filepath = './refined_dataset_with_intents.json'
    process_all_datasets(input_directory, output_filepath, max_files=2000)
