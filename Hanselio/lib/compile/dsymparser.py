import subprocess
import ntpath
import os


class FunctionDefinition:
    cmd = "_cmd"
    self_str = "self"
    void_str = "(void)"
    class_name = None
    function_return_type = None
    function_args_type_arr = []
    function_args_name_arr = []
    raw_function_signature = None
    file_name = None
    line_number = None
    function_name = None
    function_string = None
    is_function_valid = False
    can_add_param = False
    arg_index = 0

    def __init__(self):
        self.class_name = None
        self.function_return_type = None
        self.function_args_type_arr = []
        self.function_args_name_arr = []
        self.raw_function_signature = None
        self.file_name = None
        self.line_number = None
        self.function_name = None
        self.function_string = None
        self.is_function_valid = False
        self.can_add_param = False
        self.arg_index = 0

    def set_function_name(self, fn_name):
        """
            this function sets the function name
            :param fn_name: name of the function
            :type fn_name: String
            """
        self.function_name = fn_name

    def add_to_args_name(self, arg_name):
        """
            This function adds argument variable names to an array. It ignores self and _cmd which are added by default
            to every function
            :param arg_name: name of the argument
            :type arg_name: String
            """

        if self.arg_index >= 2:
            self.function_args_name_arr.append(arg_name)

    def add_to_args_type(self, arg_type):
        """
        This function adds agrument type to an array. It ignores arg type for self and _cmd
        :param arg_type: name of the argument type
        :type arg_type: String
        """

        if self.arg_index < 2:
            self.arg_index += 1
            return

        self.function_args_type_arr.append(arg_type)



    def refactor_function_name(self):
        """
        This function refactors the function output by dwarfdump in a valid format of type
        -/+ (return_type) method_name:( argumentType1 )argumentName1 joiningArgument2:( argumentType2 )argumentName2 ...
        """


        if not self.check_if_function_is_valid():
            return

        prefix_string = "-"

        if self.function_name.startswith('+'):
            prefix_string = "+"

        if self.function_return_type is None:
            self.function_return_type = self.void_str

        self.function_return_type = self.function_return_type.replace("( ", "(").replace(" )", ")")
        self.function_name = self.function_name.strip('-').strip('+').strip('[').strip(']').split(" ")[1]
        self.function_name = prefix_string + " " + self.function_return_type + " " + self.function_name

        function_name_arr = self.function_name.split(":")
        self.function_string = ""

        if len(self.function_args_name_arr) > 0:
            for i in range(0, len(self.function_args_name_arr)):

                param_type = self.function_args_type_arr[i]
                param_name = self.function_args_name_arr[i]
                self.function_string += function_name_arr[i] + ":(" + param_type + ")" + param_name + " "
        else:
            self.function_string = self.function_name


    def check_if_function_is_valid(self):
        """
            Check if a function is valid. The current implementation ensures strict check for ObjC type functions.
            Currently, it ignores blocks, c type methods etc
            """
        if self.function_name is not None and \
                self.function_name.endswith(']') and \
                (self.function_name.startswith('+') or self.function_name.startswith('-')) \
                and not ("cxx_destruct" in self.function_name):
            self.is_function_valid = True

            return self.is_function_valid


    def get_function_string(self):
        """
            Formats the function string
            :return: ClassName;FunctionDefinition
            :rtype: String
            """
        return ntpath.basename(self.file_name) + ";" + self.function_string


class DSYMParser:
    function_arr = []

    function_def = FunctionDefinition()
    function_dict = {}
    is_tag_subprogram = False
    is_tag_formal_param = False

    can_break_loop = False
    null = "NULL"
    # TAG_subprogram defines the start of the method
    tag_subprogram = "TAG_subprogram"
    # TAG_formal_parameter declares different types of arguments passed to the method
    tag_formal_param = "TAG_formal_parameter"
    # TAG_variable declares different types of variables created in the method.
    # In this version, the program ignores such variables.
    tag_variable_ = "TAG_variable"
    at_name = "AT_name"
    at_decl_file = "AT_decl_file"
    at_type = "AT_type("
    f = None

    def __init__(self):
        pass

    def create_function(self):
        self.function_def.refactor_function_name()

        if self.function_def.is_function_valid:
            func_str = self.function_def.get_function_string()
            if not (func_str in self.function_dict):
                self.f.write(func_str)
                self.f.write("\n")
                self.function_arr.append(self.function_def)
                self.function_dict[func_str] = self.function_def
        self.reset_vars()


    def handle_null(self):
        self.can_break_loop = True

    def handle_tag_subprogram(self):
        self.is_tag_subprogram = True
        self.is_tag_formal_param = False

    def handle_tag_formal_param(self):
        self.is_tag_formal_param = True
        self.is_tag_subprogram = False

    def handle_tag_variable(self):
        self.is_tag_formal_param = False
        self.is_tag_subprogram = False
        self.can_break_loop = True

    def handle_at_name(self, line):
        name = ' '.join(line.split()[1:-1]).strip('"')

        if self.is_tag_subprogram:
            self.function_def.set_function_name(name)
        elif self.is_tag_formal_param:
            self.function_def.add_to_args_name(name)


    def handle_at_decl_file(self, line):
        name = ' '.join(line.split()[1:-1]).strip('"')

        if self.is_tag_subprogram:
            self.function_def.file_name = name

    def handle_at_type(self, line):
        if self.is_tag_subprogram:
            self.function_def.function_return_type = ' '.join(line.split()[2:-1]).strip('"')
        elif self.is_tag_formal_param:
            function_param_str = ' '.join(line.split()[2:-1]).strip("(").strip(")").strip(" ")
            self.function_def.add_to_args_type(function_param_str)


    def reset_vars(self):
        self.function_def = FunctionDefinition()
        self.is_tag_subprogram = False
        self.is_tag_formal_param = False
        self.can_break_loop = False
        self.can_add_param = False


    def parse_dsym_file(self, dsym_file_path):
        """
            Parses a dSYM file and find out all methods and classes
            :param dsym_file_path: path for dSYM file
            :type dsym_file_path: String
            """
        self.f = open(os.path.expanduser("~/Desktop/Hansel/function-list"), "w+")

        out = subprocess.Popen(['dwarfdump', dsym_file_path], stdout=subprocess.PIPE)

        for line in out.stdout:
            line = line.strip()

            if self.null in line:
                self.handle_null()
            elif self.tag_subprogram in line:
                self.handle_tag_subprogram()
            elif self.tag_formal_param in line:
                self.handle_tag_formal_param()
            elif self.tag_variable_ in line:
                self.handle_tag_variable()
            elif line.startswith(self.at_name):
                self.handle_at_name(line)
            elif line.startswith(self.at_decl_file):
                self.handle_at_decl_file(line)
            elif line.startswith(self.at_type):
                self.handle_at_type(line)
            else:
                if self.can_break_loop:
                    self.create_function()


        self.f.close()

dsymParser = DSYMParser()
dsymParser.reset_vars()
dsymParser.parse_dsym_file(os.path.expanduser("~/Desktop/Hansel/crumb.dSYM"))
