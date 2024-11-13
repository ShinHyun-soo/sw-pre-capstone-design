import json
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# Initialize OpenAI client
client = OpenAI(
    api_key="OPENAI_API_KEY")



def generate_prompt(question, answer):
    prompt = f"""
    Please analyze the question, answer, and answer breakdown to detect the intent elements that can be identified in the question and answer by reffering to the intent element characteristics. 
      
    If an element is not included in the five intent elements, categorize it 'Other'.
    
    ###
    <<5 Intent Element Traits>>
    Personality characteristic : Questions or answers to identify the personality or disposition of the applicant.
    Philosophy characteristic : Questions and answers that reveal one's beliefs or ideas, thoughts, etc. that he/she considers important.
    Self-improvement characteristic : Questions about self-improvement or answers that include trying to improve oneself or to do something self-directedly.
    Insight characteristic : Questions and answers asking what the applicant is thinking about a situation or phenomenon, or solutions that provide the best choice for the current situation.
    Expertise characteristic : Questions or answers related to knowledge of specific occupational jargon or concepts, or questions or answers that confirm applicants' occupational expertise.

    Other (Work Experience, Self-Description, Adaptability, ...(omit))
    ###
    
    ###
    <<Interview Question and answers with answer brakdown>>
    
    Question: {question}
    Answer: {answer}
    """
    #Answer breakdown : {answer breakdown infomation}
    return prompt


def evaluate_prompt(question, answer):
    prompt = f"""
    Using the characteristics of appropriate and inappropriate responses below, please evaluate the interviewee's interview demeanor and the quality of their responses as evidenced by the given question and answer information to determine the appropriateness of the answer.
    Please circle an O for appropriate and an X for inappropriate. And also include 3-4 lines of your analysis.
    
    ###
    [Characteristics of an appropriate answer]
    
    [Characteristics of an inappropriate answer]
    
    * [Expertise essential considerations]
    ###
    
    ###
    <<Interview question and answers with answer breakdown>>
    Question: {question}
    Answer: {answer}
    """
    # Answer breakdown : {answer breakdown infomation}
    return prompt


def clean_response_content(content):
    # Remove markdown code block markers if present
    content = content.replace('```json', '').replace('```', '').strip()
    return content


def refine_dataset_with_llm(data):
    try:
        # Extract question and answer text
        question_text = data["dataSet"]["question"]["raw"]["text"]
        answer_text = data["dataSet"]["answer"]["raw"]["text"]

        # Generate prompt
        prompt = generate_prompt(question_text, answer_text)

        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7
        )

        # Debug: Print raw response
        print("Raw API Response Content:")
        print(response.choices[0].message.content)

        try:
            # Clean and parse JSON response
            content = clean_response_content(response.choices[0].message.content)
            categorized_intents = json.loads(content)

            # Create refined entry
            refined_entry = {
                "question": question_text,
                "answer": answer_text,
                "categorized_intents": categorized_intents
            }

            return [refined_entry]

        except json.JSONDecodeError as e:
            print(f"JSON Parsing Error: {e}")
            print("Response content that failed to parse:")
            print(content)
            return [{
                "question": question_text,
                "answer": answer_text,
                "categorized_intents": {
                    "error": "Failed to parse API response",
                    "raw_response": content
                }
            }]

    except Exception as e:
        print(f"Error processing data: {str(e)}")
        return []


# Main execution
try:
    # Read JSON file
    with open('./data/ckmk_d_ard_f_e_101874.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    # Process dataset
    refined_data = refine_dataset_with_llm(data)

    # Save refined data
    if refined_data:
        with open('./refined_dataset_with_intents.json', 'w', encoding='utf-8') as file:
            json.dump(refined_data, file, ensure_ascii=False, indent=4)
        print("Dataset has been successfully refined.")
    else:
        print("No data was processed successfully.")

except Exception as e:
    print(f"Error in main execution: {str(e)}")



