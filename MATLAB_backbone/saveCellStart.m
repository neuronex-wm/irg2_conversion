function [nwb, CS] = saveCellStart(nwb, CS, sessionTag)

if strcmp(sessionTag, nwb.general_subject.subject_id)
   nwb.session_start_time = CS.sessionStart;
else
   CS.sessionStart = CS.cStart;
   nwb.session_start_time = CS.sessionStart;
   sessionTag = nwb.general_subject.subject_id;
end