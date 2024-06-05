import json
from openai import OpenAI
import random

# Initialize OpenAI client
client = OpenAI(
    organization='*',
    project='*',
    api_key='*'
)

def parse_commands(file_path):
    categories = {}
    current_category = None

    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if line.startswith('#'):
                current_category = line[1:].strip()
                categories[current_category] = []
                print(f"New category detected: {current_category}")
            elif line:
                command, description = line.split(':')
                command = command.strip()
                description = description.strip()
                categories[current_category].append((command, description))
                print(f"Command added under {current_category}: {command} - {description}")

    return categories

def generate_user_query(command, description, category):
    ppa_constraints = ["low power consumption", "high performance", "minimal area"]
    ppa_constraint = random.choice(ppa_constraints)
    sys_prompt = '''
    Given the following command and its description, generate a natural language query instructing a llm to set this particular command in the tcl file. The PPA constraints can be one of the following: "low power consumption", "high performance", "minimal area". For constraints expecting scalar or string values, add placeholders {string}, {int}, and {float}.
    Examples:       
    Prompt:     
    Command: set_dont_use      
    Description: Prevents specific cells from being used in synthesis.       
    PPA Constraint: low power consumption       
    Output: Given the following TCL file, optimize for low power consumption without using the {string} cell in the synthesis.      

    Prompt:      
    Command: set_max_delay      
    Description: Sets the maximum delay for a path.      
    PPA Constraint: minimal area       
    Output: Given the following TCL file, optimize for minimal area by setting the maximum delay for a path to {float} ns.
    '''

    prompt = f'''
    Prompt: 
    Command: {command}
    Description: {description}
    PPA Constraint: {ppa_constraint}
    Output:     
    '''

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": sys_prompt},
            {"role": "user", "content": prompt}
        ],
        temperature=1
    )
    output = response.choices[0].message.content
    return output, ppa_constraint

def create_dataset(commands):
    dataset = []
    for category, items in commands.items():
        for command, description in items:
            output_query, ppa_constraint = generate_user_query(command, description, category)
            dataset.append({
                'command': command,
                'description': description,
                'category': category,
                'ppa_constraint': ppa_constraint,
                'query': output_query
            })
    return dataset

def save_to_json(dataset, filename='dataset2.json'):
    with open(filename, 'w') as f:
        json.dump(dataset, f, indent=4)

# Usage
commands = parse_commands('commands2.txt')
dataset = create_dataset(commands)
save_to_json(dataset)
