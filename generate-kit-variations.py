#!python3

# Script for generating some shirt/pant color variations
# Reads *.json and writes *{1,2,4,5,6,7,8}.kit files

VARIATIONS = [
    # 1
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp', 'Green'),
     ('HeadGear', 'HeadGear:BP_Hat_BaseBall', 'OD'),
     ('Belt', 'Belt:BP_Battlebelt_TF', 'RangerGreen')],
    # 2
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp', 'Red'),
     ('HeadGear', 'HeadGear:BP_Hat_BaseBall', 'Tan'),
     ('Belt', 'Belt:BP_Battlebelt_TF', 'Black')],
    # 3
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp', 'Tan'),
     ('HeadGear', 'HeadGear:BP_Hat_BaseBall_Rev', 'Tan')],
    # 4
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp_Plain', 'Black'),
     ('HeadGear', 'HeadGear:BP_Hat_WatchCap', 'Black'),
     ('Belt', 'Belt:BP_Battlebelt_TF', 'Black')],
    # 5
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp_Plain', 'Navy'),
     ('HeadGear', 'HeadGear:BP_Hat_BaseBall_Rev', 'Black'),
     ('Belt', 'Belt:BP_Battlebelt_TF', 'Black')],
    # 6
    [('Shirt', 'Shirt:BP_Shirt_Under', 'Red'),
     ('Pants', 'Pants:BP_Pants_Jeans', 'Blue'),
     ('HeadGear', 'HeadGear:BP_Hat_WatchCap', 'Tan'),
     ('Belt', 'Belt:BP_Battlebelt_TF', 'Black')],
    # 7
    [('Shirt', 'Shirt:BP_Shirt_Under', 'Navy'),
     ('Pants', 'Pants:BP_Pants_Jeans', 'Blue'),
     ('HeadGear', 'HeadGear:BP_Hat_WatchCap', 'Black'),
     ('Belt', 'Belt:BP_Battlebelt_TF', 'Black')],
    # 8
    [('Shirt', 'Shirt:BP_Shirt_Under', 'Khaki'),
     ('Pants', 'Pants:BP_Pants_Jeans', 'Blue'),
     ('HeadGear', 'HeadGear:BP_Hat_WatchCap', 'Black'),
     ]
]

VARIATIONS_FOR_PARAM = [
    # 1
    [('Shirt', 'Shirt:BP_Shirt_Under', 'Black')],
    # 2
    [('Shirt', 'Shirt:BP_Shirt_Under', 'Grey')]
]

VARIATIONS_FOR_HVT = [
    # 1
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp_Plain', 'Black')],
    # 2
    [('Shirt', 'Shirt:BP_Shirt_ButtonUp', 'Tan'), ('Belt', 'Belt:BP_Battlebelt_TF', 'Tan')]
]

import json


def load_kit(name):
    f = open(name)
    data = json.load(f)
    f.close()
    return data


def process_file(filename, variation_list):
    i = 0
    print("Processing " + filename)
    for variation_list in variation_list:
        i = i + 1
        data = load_kit(filename + '-template.json')

        for (type, item, skin) in variation_list:
            for obj in data['Data']:
                if obj['Type'] == 'Outfit' or obj['Type'] == 'Gear':
                    for outfit_item in obj['Data']:
                        if outfit_item['Type'] == type:
                            if item is None:
                                obj['Data'].remove(outfit_item)
                            else:
                                outfit_item['Item'] = item
                                outfit_item['Skin'] = skin

        outfile_name = filename + str(i) + '.kit'
        print('Writing ' + outfile_name)
        with open(outfile_name, 'w', newline='\n') as outfile:
            outfile.write(json.dumps(data, indent='\t'))
            outfile.write("\n")


def main():
    prefix_list = ['Narcos/Civ',
                   'Narcos/Tango_AR',
                   'Narcos/Tango_SMG',
                   'Narcos/Tango_SNP',
                   'Narcos/Tango_STG',
                   'Narcos/Tango_HDG']
    for filename_prefix in prefix_list:
        process_file('GroundBranch/Content/GroundBranch/AI/Loadouts/' + filename_prefix, VARIATIONS)

    prefix_list = ['Narcos/Param_AR',
                   'Narcos/Param_SMG',
                   'Narcos/Param_SNP',
                   'Narcos/Param_STG'
                   ]
    for filename_prefix in prefix_list:
        process_file('GroundBranch/Content/GroundBranch/AI/Loadouts/' + filename_prefix, VARIATIONS_FOR_PARAM)

    process_file('GroundBranch/Content/GroundBranch/AI/Loadouts/Narcos/HVT_AR', VARIATIONS_FOR_HVT)


if __name__ == "__main__":
    main()
