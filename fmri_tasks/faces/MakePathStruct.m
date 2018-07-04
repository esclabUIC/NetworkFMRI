function path = MakePathStruct()

    path.main = pwd;
    path.scripts = fullfile(path.main,'scripts');
    path.data = fullfile(path.main,'data');
    cd(path.main);

end