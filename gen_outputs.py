inputs_filename  = 'data_unpack_test_inputs.mem'
outputs_filename = 'data_unpack_test_outputs.mem'
packet_size = 7

with open(inputs_filename, 'r') as f:
    input_lines = f.readlines()
    print("Read from inputs file " + inputs_filename)


in_transaction = False

transactions = []
packets = []

for index in range(0, len(input_lines)):
    line = input_lines[index]

    if line.startswith('1') or line.startswith('0'):
        line = line.replace('_', '') #strip underscores
        line = line.replace(' ', '') #strip spaces

        if line[1] == '1' and line[2] == '1': #eop and valid_in
            in_transaction = False

        if line[0] == '1' and line[2] == '1': #sop and valid_in
            transactions.append("")
            in_transaction = True

        if in_transaction:
            transactions[-1] += line[3:35]


for index in range(0, len(transactions)):
    chunks = [transactions[index][i:i+packet_size] for i in range(0, len(transactions[index]), packet_size)]
    filler = '0'*(7-len(chunks[-1])) #0 MSB's for final packet

    chunks[-1] = '0_1_' + filler + chunks[-1] #add filler and eop
    chunks[0] = '1_0_' + chunks[1] #add sop to first chunk

    for i in range(1, len(chunks) - 1):
        chunks[i] = "0_0_" + chunks[i]

    packets.append("")
    packets.append("//Packet #" + str(index))
    packets.extend(chunks)

with open(outputs_filename, 'w+') as f:
    f.write("//sop_out | eop_out | data_out\n\n")
    f.writelines('\n'.join(packets))
    print("Written to outputs file " + outputs_filename)
