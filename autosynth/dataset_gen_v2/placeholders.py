import json
# from openai import OpenAI

# Initialize the OpenAI client (commented out for now)
# client = OpenAI(
#     organization='org-VR0PrQFpMVbh4ELxxSHDbdb7',
#     project='proj_P3nuY0NXfQnZVaD2tmJPdSbi',
#     api_key='sk-proj-P7SKNKhDWsWGmewN2FDaT3BlbkFJKcN4foFiI6oZ3jddpMBY'
# )

# Load the dataset
with open("dataset_new.json", "r") as file:
    data = json.load(file)

# Function to generate example values
def generate_examples(command, value_type):
    prompt = f"Generate 10 different example values/names/objects etc. for the command '{command}' with value type '{value_type}'."
    print(f"Prompt for generating examples:\n{prompt}\n")
    # response = client.chat.completions.create(
    #     model="gpt-3.5-turbo",
    #     messages=[
    #         {"role": "system", "content": "You are a helpful assistant."},
    #         {"role": "user", "content": prompt}
    #     ],
    #     temperature=1
    # )
    # return response.choices[0].message.content.split('\n')
    return ["example1", "example2", "example3", "example4", "example5", "example6", "example7", "example8", "example9", "example10"]

# Function to generate final commands
def generate_final_commands(syntax, examples):
    prompt = f"Generate TCL commands using the syntax '{syntax}' and the following examples: {examples}. Provide one command for each example."
    print(f"Prompt for generating final commands:\n{prompt}\n")
    # response = client.chat.completions.create(
    #     model="gpt-3.5-turbo",
    #     messages=[
    #         {"role": "system", "content": "You are a helpful assistant."},
    #         {"role": "user", "content": prompt}
    #     ],
    #     temperature=1
    # )
    # return response.choices[0].message.content.split('\n')
    return ["final_command1", "final_command2", "final_command3", "final_command4", "final_command5", "final_command6", "final_command7", "final_command8", "final_command9", "final_command10"]

# Process each entry in the dataset
for entry in data:
    examples = generate_examples(entry['command'], entry['value_type'])
    final_commands = generate_final_commands(entry['syntax'], examples)
    entry['query_examples'] = examples
    entry['final_commands'] = final_commands

# Save the updated dataset
with open("dataset_new_updated_test.json", "w") as file:
    json.dump(data, file, indent=4)

print("Dataset updated and saved as 'dataset_new_updated.json'.")
