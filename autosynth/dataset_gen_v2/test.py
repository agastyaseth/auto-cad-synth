import json
from openai import OpenAI
import random

# Initialize OpenAI client
client = OpenAI(
    organization='org-VR0PrQFpMVbh4ELxxSHDbdb7',
    project='proj_P3nuY0NXfQnZVaD2tmJPdSbi',
    api_key='sk-proj-P7SKNKhDWsWGmewN2FDaT3BlbkFJKcN4foFiI6oZ3jddpMBY'
)

def generate_user_query(command, description, syntax, category):
    ppa_constraints = ["low power consumption", "high performance", "minimal area"]
    ppa_constraint = random.choice(ppa_constraints)
    sys_prompt = '''
    Given the following command, description, and the syntax generate a natural language query instructing a llm to set this particular command in the tcl file. The PPA constraints can be one of the following: "low power consumption", "high performance", "minimal area". For constraints expecting scalar or string values, add placeholders {cell_name}, {port_name}, {int}, {float}, etc.
    Examples:      
    Prompt:      
    Command: set_dont_use      
    Description: Prevents specific cells from being used in synthesis. 
    Syntax: set_dont_use <cell_names>      
    PPA Constraint: low power consumption       

    Output: 
    Given the following TCL file, optimize for low power consumption without using the {cell_name} cell in the synthesis.      

    Prompt:      
    Command: set_max_delay      
    Description: Sets the maximum delay for a path.      
    Syntax: set_max_delay <delay_value> -from <source_objects> -to <destination_objects>
    PPA Constraint: minimal area       

    Output: Given the following TCL file, optimize for minimal area by setting the maximum delay for the path from {object} to {object} to {float} ns.
    '''

    prompt = f'''
    Prompt: 
    Command: {command}
    Description: {description}
    Syntax: {syntax}
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

def main():
    input_file = 'commands2.json'
    output_file = 'dataset_new.json'

    # Read the JSON data from the file
    with open(input_file, 'r') as file:
        data = json.load(file)

    # Process each command entry to generate queries and append results
    enhanced_data = []
    for entry in data:
        command = entry['command']
        description = entry['description']
        syntax = entry['syntax']
        category = entry['constraint_type']
        
        # Generate the query using the provided function
        query_output, ppa_constraint = generate_user_query(command, description, syntax, category)
        
        # Append the generated output and the chosen PPA constraint to the entry
        entry['query'] = query_output
        entry['ppa_constraint'] = ppa_constraint
        
        enhanced_data.append(entry)
    
    # Write the enhanced data back to a new JSON file
    with open(output_file, 'w') as file:
        json.dump(enhanced_data, file, indent=4)

if __name__ == '__main__':
    main()