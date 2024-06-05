import json
import random
from transformers import AutoTokenizer, AutoModelForCausalLM
from huggingface_hub import login


# Authentication with Hugging Face Hub
# hf_token = "*"
# login(hf_token)

# Load tokenizer and model
# tokenizer = AutoTokenizer.from_pretrained("meta-llama/Meta-Llama-3-8B-Instruct")
# model = AutoModelForCausalLM.from_pretrained("meta-llama/Meta-Llama-3-8B-Instruct")

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

# def generate_user_query(command, description):
#     ppa_constraints = ["low power consumption", "high performance", "minimal area"]
#     selected_ppa = random.choice(ppa_constraints)
    
#     prompt = f"<|begin_of_text|><|start_header_id|>system<|end_header_id|> You are an AI trained to generate sample queries based on user instructions and examples.<|eot_id|> <|start_header_id|>user<|end_header_id|> Generate a query like the following example which instructs to set specific : Modify the TCL file to optimize for {selected_ppa} without using the NangateOpenCellLibrary/AOI cell in the synthesis. Include the command '{command}' which {description}.\nassistant"
#     print("Example prompt: ", prompt)
#     inputs = tokenizer(prompt, return_tensors='pt')
#     outputs = model.generate(**inputs, max_length=150, num_return_sequences=1)
#     query = tokenizer.decode(outputs[0], skip_special_tokens=True)
#     print("Generated query: ", query)
#     return query, command

def generate_user_query(command, description, ppa_constraint):
    prompt = f'''
    Given the following command and its description, generate a natural language query instructing a llm to set this particular command in the tcl file. The PPA constraints can be one of the following: "low power consumption", "high performance", "minimal area". Also add an example value for the constraint (for example if the command is set_dont_use, make up a random cell name like "NangateOpenCellLibrary/AOI")
    Examples: 
    Prompt: 
    Command: set_dont_use 
    Description: Prevents specific cells from being used in synthesis.  
    PPA Constraint: low power consumption  
    Output: Given the following TCL file, optimize for low power consumption without using the "NangateOpenCellLibrary/AOI" cell in the synthesis.

    Prompt: 
    Command: set_max_delay 
    Description: Sets the maximum delay for a path. 
    PPA Constraint: minimal area  
    Output: Given the following TCL file, optimize for minimal area by setting the maximum delay for a path to 5.0 ns.
    
    Prompt: 
    Command: {command}
    Description: {description}
    PPA Constraint: {ppa_constraint}
    Output: 
    '''
    response = client.chat.completions.create(
        model="gpt-3.5-turbo-0125",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": "Output: "}
        ],
        temperature=0.1
    )

    return response.choices[0].message.content

def generate_tcl_modification(command, category):
    if 'dont_use' in command:
        return f"# {category}\nset_dont_use {{NangateOpenCellLibrary/AOI}}  # exclude AOI cell from NangateOpenCellLibrary\n"
    # Return a default modification if no specific one matched
    print(f"No TCL modification matched for command: {command}.")
    return f"# {category}\n{command} # default modification\n"

def create_dataset(commands):
    dataset = []
    for category, items in commands.items():
        for command, description in items:
            user_query, cmd = generate_user_query(command, description)
            tcl_modification = generate_tcl_modification(cmd, category)
            dataset.append({
                'user_query': user_query,
                'tcl_modification': tcl_modification
            })
            print(f"Dataset entry created: {user_query} | {tcl_modification}")

    return dataset

def save_to_json(dataset, filename='dataset.json'):
    with open(filename, 'w') as f:
        json.dump(dataset, f, indent=4)

commands = parse_commands('commands.txt')
dataset = create_dataset(commands)
save_to_json(dataset)
