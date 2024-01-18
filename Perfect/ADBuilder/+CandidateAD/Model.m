classdef Model < CandidateAD.Node
    properties
        ModelDatabase
    end

    methods
        function modelObj = Model(varargin)
            modelObj@CandidateAD.Node(varargin{:});
        end

        function element = lookup(this, elementID)
            checkModelDatabaseExists(this);

            element = this.ModelDatabase.getElement(elementID);
        end

        function register(this, element)
            checkModelDatabaseExists(this);

            this.ModelDatabase.addElement(element.ExternalID, element);
        end

        function checkModelDatabaseExists(this)
            if isempty(this.ModelDatabase)
                mdlIdx = CandidateAD.getModelIndex;
                cleanDB = CandidateAD.Index;

                mdlDB = mdlIdx.getElement(this.Name);
                if isempty(mdlDB)
                    mdlIdx.addElement(this.Name, cleanDB);    
                else
                    mdlIdx.updateElement(this.Name, cleanDB);    
                end

                this.ModelDatabase = cleanDB;
            end
        end

        function doPublish(this, varargin)
            modelName = matlab.lang.makeValidName(this.Name);
            % Deconflict filenames
            files = dir(pwd);
            [~, fileNames] = fileparts({files.name});
            modelName = ADBuilder.internal.nextName(fileNames, modelName);

            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.newActivity(modelName);

            cleanup = onCleanup(@()open_system(modelName));
        end

        function setModel(this)
            % method override during construction.
            this.Model = this;
        end
    end
end