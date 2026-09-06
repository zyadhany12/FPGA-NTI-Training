    // TODO: Add a module-level attribute here (e.g., (* optimize = "off" *)) module lexical_demo; // TODO: 
    (* optimize = "off" *) module lexical_demo
    (
    // 1. Strings 
    // A string requires 8 bits per character. "Hello World" is 11 characters.     // Declare a register named ‘my_string’
        output reg [87:0] message,

    // 2. Case Sensitivity & Identifiers 
    // Declare two 8-bit registers named 'Data_Val' and 'data_val' 
        output reg [7:0]Data_Val,
        output reg [7:0]data_val,

    // 3. Logic Values & Literal Integers 
    // Declare a 12-bit register named 'mixed_logic'
        output reg [11:0] mixed_logic,

    // 5. Attributes on variables 
    // use (* keep = "true" *) to a net called ‘protected_wire’
        (* keep = "true" *)  output wire protected_wire

    );
     // 4. Literal Real Numbers 
    // Declare a 'real' variable named 'analog_voltage' 
        real analog_voltage;
 
    initial begin 
        // --- Assignments --- // TODO: 
        // String assignment 
        // TODO: assign "Hello World" to my_string
        message = "Hello World";
        Data_Val = 8'hAA; data_val <= 8'h55;
        mixed_logic = 12'b1010_xxxx_zzzz;
        analog_voltage = 3.3e-3; 
         
 
        // --- Display Results --- 
        // $display statements automatically print to the console. 
 
        $display("--- Lexical Conventions Output ---"); 
        $display("String Value: %s", message); 
        // TODO: Add $display statements to print variables.
        $display("Data Value: %h || data value: %h || Mixed logic: %b || Analog Voltage: %f", Data_Val, data_val, mixed_logic, analog_voltage); 
        // Hint: Use %h for hex, %b for binary, and %f for real numbers. 
        $finish;     end endmodule 


