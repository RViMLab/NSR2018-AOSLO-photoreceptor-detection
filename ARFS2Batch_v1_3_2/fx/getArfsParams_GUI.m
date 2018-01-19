function varargout = getArfsParams_GUI(varargin)
% getArfsParams_GUI MATLAB code for getArfsParams_GUI.fig
%      getArfsParams_GUI, by itself, creates a new getArfsParams_GUI or raises the existing
%      singleton*.
%
%      H = getArfsParams_GUI returns the handle to a new getArfsParams_GUI or the handle to
%      the existing singleton*.
%
%      getArfsParams_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in getArfsParams_GUI.M with the given input arguments.
%
%      getArfsParams_GUI('Property','Value',...) creates a new getArfsParams_GUI or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before getArfsParams_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to getArfsParams_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help getArfsParams_GUI

% Last Modified by GUIDE v2.5 22-Aug-2016 21:09:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @getArfsParams_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @getArfsParams_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before getArfsParams_GUI is made visible.
function getArfsParams_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to getArfsParams_GUI (see VARARGIN)

% Choose default command line output for getArfsParams_GUI
handles.output = hObject;

set(handles.dmb_fname,'string',varargin{1});

% Update defaults
if any(strcmpi(varargin,'mtskip')) % set skip motion tracking status
    def_mtskip = varargin{find(strcmpi(varargin,'mtskip')) + 1};
    if def_mtskip
        set(handles.rb_y_skip,'value',true);
        set(handles.rb_y_cluster,'enable','off');
        set(handles.rb_n_cluster,'value',true);
        set(handles.nReqText,'string','Number of frames to output');
        set(handles.mfpcValue,'enable','off');
    end
end
if any(strcmpi(varargin,'clusterwise')) % set clusterwise output status
    def_clusterwise = varargin{find(strcmpi(varargin,'clusterwise')) + 1};
    if ~def_clusterwise
        set(handles.rb_n_cluster,'value',true);
        set(handles.nReqText,'string','Number of frames to output');
        set(handles.mfpcValue,'enable','off');
    end
end
if any(strcmpi(varargin,'nReq')) % set number of frames to output
    def_nReq = varargin{find(strcmpi(varargin,'nReq')) + 1};
    set(handles.nReq,'string',def_nReq);
end
if any(strcmpi(varargin,'framesPerCluster')) 
    def_mfpc = varargin{find(strcmpi(varargin,'framesPerCluster')) + 1};
    set(handles.mfpcValue,'string',def_mfpc);
end

% Update handles structure
guidata(hObject, handles);

guidata(handles.figure1, handles);

% UIWAIT makes getArfsParams_GUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = getArfsParams_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);


% --- Executes on button press in rb_n_skip.
function rb_n_skip_Callback(hObject, eventdata, handles)
% hObject    handle to rb_n_skip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value'),
    set(handles.rb_y_cluster,'enable','on');
    set(handles.mfpcValue,'enable','on');
end


% --- Executes on button press in rb_y_skip.
function rb_y_skip_Callback(hObject, eventdata, handles)
% hObject    handle to rb_y_skip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if get(hObject,'Value'),
    set(handles.rb_y_cluster,'enable','off')
    set(handles.rb_n_cluster,'value',true);
    set(handles.nReqText,'string','Number of frames to output');
    set(handles.mfpcValue,'enable','off');
end


% --- Executes on button press in rb_y_cluster.
function rb_y_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to nReq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value')
    set(handles.nReqText,'string','Number of frames from each cluster to output');
    set(handles.nReq,'enable','on');
    set(handles.mfpcValue,'enable','on');
end


% --- Executes on button press in rb_n_cluster.
function rb_n_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to nReq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value'),
    set(handles.nReqText,'string','Number of frames to output');
    set(handles.mfpcValue,'enable','off');
end


% --- Executes during object creation, after setting all properties.
function nReq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nReq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function nReq_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to nReq (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
nReq = str2double(get(hObject,'string'));
if ~isnumeric(nReq) || isnan(nReq) || nReq <= 0 || mod(nReq,1) ~= 0
    set(handles.nReq,'backgroundcolor',[1 0 0]);
    set(handles.pushButtonOK,'enable','off');
else
    set(handles.nReq,'backgroundcolor',[1 1 1]);
    % check if other field is valid
    if all(get(handles.mfpcValue,'backgroundcolor') == [1 1 1])
        set(handles.pushButtonOK,'enable','on');
    end
end


% --- Executes during object creation, after setting all properties.
function mfpcValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mfpcValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function mfpcValue_Callback(hObject, eventdata, handles)
% hObject    handle to nReq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
mfpc = str2double(get(hObject,'string'));
if ~isnumeric(mfpc) || isnan(mfpc) || mfpc <= 0 || mod(mfpc,1) ~= 0
    set(handles.mfpcValue,'backgroundcolor',[1 0 0]);
    set(handles.pushButtonOK,'enable','off');
else
    set(handles.mfpcValue,'backgroundcolor',[1 1 1]);
    % check if other field is valid
    if all(get(handles.nReq,'backgroundcolor') == [1 1 1])
        set(handles.pushButtonOK,'enable','on');
    end
end


% --- Executes on button press in pushButtonOK.
function pushButtonOK_Callback(hObject, eventdata, handles)
% hObject    handle to pushButtonOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = struct('mtskip',           get(handles.rb_y_skip,'value'), ...
                        'clusterwise',      get(handles.rb_y_cluster,'value'), ...
                        'nReq',             get(handles.nReq,'string'), ...
                        'framesPerCluster', get(handles.mfpcValue,'string'));

% Update handles structure
guidata(hObject, handles);
% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, use UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key,'return')
    pushButtonOK_Callback(hObject, eventdata, handles)
end


% --- Executes on key press with focus on pushButtonOK and none of its controls.
function pushButtonOK_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key,'return')
    pushButtonOK_Callback(hObject, eventdata, handles)
end


% --- Executes on key press with focus on rb_n_skip and none of its controls.
function rb_n_skip_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key,'return')
    pushButtonOK_Callback(hObject, eventdata, handles)
end


% --- Executes on key press with focus on rb_y_skip and none of its controls.
function rb_y_skip_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key,'return')
    pushButtonOK_Callback(hObject, eventdata, handles)
end


% --- Executes on key press with focus on rb_y_cluster and none of its controls.
function rb_y_cluster_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key,'return')
    pushButtonOK_Callback(hObject, eventdata, handles)
end


% --- Executes on key press with focus on rb_n_cluster and none of its controls.
function rb_n_cluster_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key,'return')
    pushButtonOK_Callback(hObject, eventdata, handles)
end


% --- Executes during object creation, after setting all properties.
function dmb_fname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dmb_fname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in back_button.
function back_button_Callback(hObject, eventdata, handles)
% hObject    handle to back_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = struct('backButtonPressed', true);

% Update handles structure
guidata(hObject, handles);
% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


% --- Executes during object creation, after setting all properties.
function back_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to back_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
