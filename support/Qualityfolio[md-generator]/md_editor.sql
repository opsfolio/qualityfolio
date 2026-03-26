-- Markdown Editor Page
SELECT 'shell' AS component,
       'Markdown Editor' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
       json_array(
           json_object('title', 'Generator',        'link', 'entries.sql',  'icon', 'pencil'),
           json_object('title', 'Markdown Editor',  'link', 'md_editor.sql','icon', 'file-text', 'active', true),
           json_object('title', 'Settings',         'link', 'settings.sql', 'icon', 'settings')
       ) AS menu_item,
        json_array(
            '/js/layout.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/js/chat.js?v='   || CAST(STRFTIME('%s', 'now') AS TEXT),
            'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js',
            '/js/pikaday.js',
            '/js/md-date-picker.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/js/md-parser.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/js/results.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/js/md-editor-core.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
            '/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/css/chat.css?v='  || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/css/pikaday.css',
            '/css/treeview.css',
            'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
        ) AS css,
        '/images/favicon.ico' AS favicon,
        '© 2026 Qualityfolio. Test assurance as living Markdown.' AS footer;
        

SET _members   = (SELECT json_group_array(json_object('name', full_name, 'id', id)) FROM team_members);
SET _scenarios = (SELECT json_group_array(name) FROM scenario_types);
SET _execs     = (SELECT json_group_array(name) FROM execution_types);
SET _statuses  = (SELECT json_group_array(name) FROM test_case_statuses);

-- CSP-safe: inject master data as data-* attributes on a hidden element (no inline script)
SELECT 'html' AS component,
    '<div id="qfme-config" hidden'
    || ' data-members=''' || REPLACE(COALESCE($_members,'[]'), '''', '&apos;') || ''''
    || ' data-scenarios=''' || REPLACE(COALESCE($_scenarios,'[]'), '''', '&apos;') || ''''
    || ' data-execs=''' || REPLACE(COALESCE($_execs,'[]'), '''', '&apos;') || ''''
    || ' data-statuses=''' || REPLACE(COALESCE($_statuses,'[]'), '''', '&apos;') || ''''
    || '></div>' AS html;

SELECT 'html' AS component, '
<div id="qfme-root">
    <style>
        .editor-container {
            display: flex;
            min-height: calc(100vh - 140px);
            width: 100%;
            gap: 1.2rem;
            padding: 1.2rem;
            background: linear-gradient(135deg, rgba(248, 250, 252, 0.5) 0%, rgba(241, 245, 249, 0.3) 100%);
        }

        /* Top Dock Toolbar Styles */
        .action-dock-container {
            width: 100%;
            display: none; /* Toggled by JS */
            padding: 0.75rem 1.5rem;
            background: linear-gradient(135deg, rgba(248, 250, 252, 0.95) 0%, rgba(241, 245, 249, 0.9) 100%);
            border-bottom: 1px solid rgba(226, 232, 240, 0.6);
            z-index: 50;
            position: sticky;
            top: 0;
            justify-content: flex-end;
            padding-right: 2rem;
            backdrop-filter: blur(8px);
        }
        .action-dock-container.visible {
            display: flex;
            animation: slideDown 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .action-dock {
            background: rgba(255, 255, 255, 0.85);
            border: 1px solid rgba(226, 232, 240, 0.8);
            border-radius: 10px;
            padding: 10px 18px;
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
            display: flex;
            align-items: center;
            gap: 1rem;
            backdrop-filter: blur(10px);
            transition: all 0.2s ease;
        }
        
        .action-dock:hover {
            border-color: rgba(226, 232, 240, 1);
            box-shadow: 0 6px 16px rgba(15, 23, 42, 0.12);
        }

        /* Reuse existing dock styles */
        .dock-section { display: flex; align-items: center; }
        .dock-section.gap-2 { gap: 0.5rem; }
        .dock-section.border-r { border-right: 1px solid rgba(226, 232, 240, 0.6); padding-right: 1rem; margin-right: 0.5rem; }
        .dock-checkbox { width: 1.1rem; height: 1.1rem; accent-color: var(--primary-color); cursor: pointer; margin-right: 0.5rem; border-radius: 5px; transition: all 0.2s; }
        .dock-checkbox:hover { accent-color: #0284c7; }
        .dock-label { font-weight: 500; font-size: 0.9rem; color: var(--text-primary); cursor: pointer; white-space: nowrap; letter-spacing: -0.5px; }
        .dock-count { font-size: 0.75rem; font-weight: 600; color: var(--text-muted); margin-left: 0.5rem; background: linear-gradient(135deg, rgba(241, 245, 249, 0.8) 0%, rgba(226, 232, 240, 0.5) 100%); padding: 0.2rem 0.5rem; border-radius: 6px; white-space: nowrap; border: 1px solid rgba(226, 232, 240, 0.4); }
        
        /* Inputs/Buttons */
        .dock-select, .dock-input, .dock-select-mini, .dock-input-date {
            height: 36px; font-size: 0.9rem; border: 1px solid rgba(203, 213, 225, 0.6); background: rgba(255, 255, 255, 0.7); border-radius: 8px; padding: 0 0.75rem; color: #334155; transition: all 0.2s ease; font-weight: 500;
        }
        .dock-select:focus, .dock-input:focus, .dock-select-mini:focus, .dock-input-date:focus {
            outline: none;
            border-color: var(--primary-color);
            background: #fff;
            box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
        }
        .dock-btn-icon { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; background: transparent; border: 1px solid transparent; border-radius: 8px; color: #64748b; cursor: pointer; transition: all 0.2s ease; }
        .dock-btn-icon:hover { background: rgba(241, 245, 249, 0.8); color: var(--primary-color); border-color: rgba(226, 232, 240, 0.5); transform: translateY(-1px); }
        .dock-btn-icon:active { transform: translateY(0); }
        
        /* Unified Blue Buttons */
        .dock-btn-primary, .dock-btn-secondary, .dock-btn-run { 
            height: 36px; 
            padding: 0 1.1rem; 
            background: linear-gradient(135deg, var(--primary-color) 0%, #0284c7 100%);
            border: none; 
            border-radius: 8px; 
            color: white; 
            font-size: 0.9rem; 
            font-weight: 600; 
            cursor: pointer; 
            display: flex; 
            align-items: center; 
            gap: 0.5rem; 
            box-shadow: 0 4px 12px rgba(14, 165, 233, 0.25); 
            transition: all 0.2s ease;
            margin-left: 0.25rem;
            letter-spacing: -0.3px;
        }
        .dock-btn-primary:hover, .dock-btn-secondary:hover, .dock-btn-run:hover { 
            background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(14, 165, 233, 0.35);
        }
        .dock-btn-primary:active, .dock-btn-secondary:active, .dock-btn-run:active {
            transform: translateY(0);
            box-shadow: 0 2px 8px rgba(14, 165, 233, 0.25);
        }

        /* Utility classes */
        .flex { display: flex; }
        .items-center { align-items: center; }
        .justify-between { justify-content: space-between; }
        .gap-1 { gap: 0.25rem; }
        .gap-2 { gap: 0.5rem; }
        .gap-3 { gap: 0.75rem; }
        .gap-4 { gap: 1rem; }
        .w-64 { width: 16rem; }
        .w-56 { width: 14rem; }
        .w-48 { width: 12rem; }
        .w-40 { width: 10rem; }
        .w-32 { width: 8rem; }
        .w-28 { width: 7rem; }
        .w-24 { width: 6rem; }
        .pr-2 { padding-right: 0.5rem; }
        .border-r { border-right: 1px solid var(--border-color); }
        .border-gray-200 { border-color: #e5e7eb; }
        .left-rounded { border-top-right-radius: 0; border-bottom-right-radius: 0; border-right: none; }
        .right-rounded { border-top-left-radius: 0; border-bottom-left-radius: 0; }
        
        /* Tree View (Hierarchy) Tab Styles — all levels always expanded */
        .tree-node { margin-left: 1.25rem; border-left: 1px solid rgba(226, 232, 240, 0.5); padding-left: 0.75rem; margin-top: 0.3rem; }
        .tree-node.open > .tree-children { display: block; }
        .tree-header { display: flex; align-items: center; justify-content: space-between; padding: 5px 10px; border-radius: 8px; transition: background 0.2s; }
        .tree-header:hover { background: rgba(241, 245, 249, 0.8); }
        .tree-actions { display: flex; gap: 0.75rem; opacity: 0.3; transition: opacity 0.2s; }
        .tree-header:hover .tree-actions { opacity: 1; }
        .tree-actions span:hover { text-decoration: underline; color: var(--primary-color); }
        .tree-children { display: block; }

        /* Upload Prompt */
        .upload-prompt {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            width: 100%;
            min-height: calc(100vh - 140px);
            text-align: center;
            padding: 2rem;
        }

        .upload-card {
            background: linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(248, 250, 252, 0.9) 100%);
            border: 1.5px dashed rgba(226, 232, 240, 0.8);
            border-radius: 18px;
            padding: 2.8rem 2rem;
            text-align: center;
            width: 280px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            cursor: pointer;
        }
        .upload-card:hover {
            border-color: var(--primary-color);
            box-shadow: 0 12px 32px rgba(14, 165, 233, 0.15);
            transform: translateY(-6px);
            background: linear-gradient(135deg, rgba(255, 255, 255, 1) 0%, rgba(240, 249, 255, 0.95) 100%);
        }
        .upload-card .upload-icon-wrap {
            width: 90px;
            height: 90px;
            border-radius: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem auto;
            font-size: 2.8rem;
            background: linear-gradient(135deg, rgba(14, 165, 233, 0.08) 0%, rgba(14, 165, 233, 0.04) 100%);
            transition: all 0.3s ease;
        }
        .upload-card:hover .upload-icon-wrap {
            background: linear-gradient(135deg, rgba(14, 165, 233, 0.15) 0%, rgba(14, 165, 233, 0.08) 100%);
            transform: scale(1.08);
        }
        .upload-card h3 {
            font-size: 1.15rem;
            font-weight: 700;
            margin-bottom: 0.6rem;
            color: var(--text-primary);
            letter-spacing: -0.4px;
        }
        .upload-card p {
            color: var(--text-secondary);
            font-size: 0.88rem;
            margin-bottom: 1.6rem;
            line-height: 1.6;
        }
        .upload-card-btn {
            width: 100%;
            padding: 0.625rem 1rem;
            border-radius: 8px;
            font-size: 0.875rem;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            border: 1px solid var(--border-color);
            transition: all 0.2s;
        }
        
        .upload-icon {
            font-size: 3rem;
            color: var(--primary-color);
            margin-bottom: 1.5rem;
            opacity: 0.8;
        }

        /* Split Layout */
        #mainEditorArea {
            display: none; /* Hidden strictly until upload */
            width: 100%;
            height: 100%;
        }

        /* Sidebar Tree */
        .tree-sidebar {
            width: 280px;
            background: linear-gradient(180deg, rgba(255, 255, 255, 0.95) 0%, rgba(248, 250, 252, 0.9) 100%);
            border: 1px solid rgba(226, 232, 240, 0.6);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            flex-shrink: 0;
            box-shadow: 0 2px 8px rgba(15, 23, 42, 0.05);
        }

        .tree-sidebar .tree-header {
            padding: 1.1rem;
            border-bottom: 1px solid rgba(226, 232, 240, 0.5);
            font-weight: 700;
            color: var(--text-primary);
            background: linear-gradient(135deg, rgba(248, 250, 252, 0.8) 0%, rgba(241, 245, 249, 0.6) 100%);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.95rem;
            letter-spacing: -0.3px;
        }

        .tree-content {
            flex: 1;
            overflow: auto; /* Allow both horizontal and vertical scrolling */
            padding: 0.5rem;
            /* Hide vertical scrollbar but keep horizontal if needed? No, user asked for scroll. */
        }

        /* Tree Nodes */
        ul.tree-list {
            list-style: none;
            padding-left: 0.5rem;
            margin: 0;
            min-width: max-content; /* Ensure list takes full width of longest item */
        }
        
        ul.tree-list li {
            margin: 2px 0;
        }
        
        .tree-item-label {
            display: flex;
            align-items: center;
            padding: 7px 10px;
            cursor: pointer;
            border-radius: 8px;
            color: #666 !important;
            font-size: 0.75rem;
            transition: all 0.2s ease;
            white-space: nowrap;
            font-weight: 500;
        }
        
        .tree-item-label:hover {
            background: rgba(14, 165, 233, 0.08);
            color: var(--primary-color);
            transform: translateX(3px);
        }
        
        .tree-item-label.active {
            background: rgba(14, 165, 233, 0.12);
            color: var(--primary-color);
            font-weight: 600;
        }
        
        .tree-item-label .icon {
            margin-right: 8px;
            width: 16px;
            text-align: center;
            font-size: 0.85rem;
            transition: transform 0.2s ease;
        }
        
        .tree-item-label:hover .icon {
            transform: scale(1.15);
        }
        
        .tree-children {
            display: block; /* Always expanded — full hierarchy visible by default */
            padding-left: 12px;
            margin-left: 6px;
            border-left: 2px solid rgba(14, 165, 233, 0.15);
        }
        
        .tree-dir.expanded > .tree-children {
            display: block;
        }

        /* Main Editor/Viewer */
        .editor-main {
            flex: 1;
            background: linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(248, 250, 252, 0.92) 100%);
            border: 1px solid rgba(226, 232, 240, 0.6);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(15, 23, 42, 0.05);
        }

        .editor-header {
            padding: 0.5rem 1rem;
            border-bottom: 1px solid rgba(226, 232, 240, 0.5);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 600;
            font-size: 0.95rem;
            letter-spacing: -0.3px;
        }

        .editor-content-scroll {
            flex: 1;
            overflow-y: auto;
            padding: 0;
        }
        
    /* Base Modal Core CSS */
    .modal-overlay {
        display: none;
        position: fixed;
        inset: 0;
        z-index: 10000;
        background: rgba(15, 23, 42, 0.5);
        backdrop-filter: blur(6px);
        align-items: center;
        justify-content: center;
        animation: fadeIn 0.2s ease;
    }
    @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
    .modal-overlay.active { 
        display: flex !important; 
    }
    .md-modal {
        background: #ffffff;
        border-radius: 18px;
        width: 100%;
        max-width: 650px;
        max-height: 90vh;
        display: flex;
        flex-direction: column;
        box-shadow: 0 25px 70px rgba(15, 23, 42, 0.2), 0 0 1px rgba(0, 0, 0, 0.05);
        overflow: hidden;
        border: 1px solid rgba(226, 232, 240, 0.6);
        animation: slideUp 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }
    @keyframes slideUp {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
    }
    .modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 1.5rem 1.75rem;
        border-bottom: 1px solid rgba(226, 232, 240, 0.5);
        background: linear-gradient(135deg, rgba(248, 250, 252, 0.9) 0%, rgba(241, 245, 249, 0.8) 100%);
    }
    .modal-header h3 { margin: 0; font-size: 1.1rem; font-weight: 700; color: #1e293b; letter-spacing: -0.3px; }
    .close-modal { width: 38px; height: 38px; border: 1px solid rgba(226, 232, 240, 0.5); border-radius: 10px; background: rgba(248, 250, 252, 0.8); cursor: pointer; display: flex; align-items: center; justify-content: center; color: #64748b; font-size: 1.2rem; transition: all 0.2s ease; }
    .close-modal:hover { background: rgba(226, 232, 240, 0.5); color: var(--primary-color); transform: rotate(90deg); }
    .modal-body { padding: 1.75rem; overflow-y: auto; flex: 1; }
    .modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding: 1.25rem 1.75rem; border-top: 1px solid rgba(226, 232, 240, 0.5); background: linear-gradient(135deg, rgba(248, 250, 252, 0.6) 0%, rgba(241, 245, 249, 0.4) 100%); }
    
    .form-group { margin-bottom: 14px; }
    .form-group label { display: block; font-size: 0.8rem; font-weight: 700; color: #374151; margin-bottom: 6px; letter-spacing: -0.3px; }
    .form-input { width: 100%; border: 1px solid rgba(203, 213, 225, 0.6); border-radius: 10px; padding: 9px 12px; font-size: 0.85rem; color: #1e293b; background: rgba(248, 250, 252, 0.7); font-family: inherit; transition: all 0.2s ease; }
    .form-input:focus { outline: none; border-color: var(--primary-color); background: #fff; box-shadow: 0 0 0 3.5px rgba(14, 165, 233, 0.1); }
    textarea.form-input { resize: vertical; min-height: 100px; }

    /* === Generator-identical bulk toolbar CSS === */
    .qfg-bulk-toolbar{padding: 14px 18px;display: flex;flex-direction: column;gap: 10px;box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);backdrop-filter: blur(6px);}
    .qfg-bulk-row{display: flex; flex-wrap: nowrap; gap: 8px; align-items: center;}
    .qfg-bulk-group{display: flex; align-items: center; gap: 10px;}
    .qfg-bulk-divider{width: 1px; height: 24px; background: linear-gradient(180deg, transparent 0%, rgba(226, 232, 240, 0.6) 50%, transparent 100%);}
    .qfg-bulk-spacer{flex: 1;}
    .qfg-bulk-select{padding: 6px 10px !important;border-radius: 8px !important;font-size: 0.7rem !important;color: #666 !important;height: 32px; transition: all 0.2s ease;font-weight: 500;}
    .qfg-bulk-select:focus { outline: none; border-color: var(--primary-color); background: #fff; box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1); }
    .qfg-bulk-input{padding: 6px 10px; border: 1px solid rgba(203, 213, 225, 0.6); border-radius: 8px; font-size: 0.8rem; color: #334155; background: rgba(248, 250, 252, 0.8); height: 32px; transition: all 0.2s ease;}
    .qfg-bulk-input:focus { outline: none; border-color: var(--primary-color); background: #fff; box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1); }
    .qfg-bulk-label{font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: #64748b; white-space: nowrap;}
    .qfg-select-bar{display: flex; align-items: center; gap: 12px; padding: 12px 16px; background: linear-gradient(135deg, rgba(248, 250, 252, 0.8) 0%, rgba(241, 245, 249, 0.6) 100%); border: 1px solid rgba(226, 232, 240, 0.6); border-radius: 12px; margin-bottom: 10px;}
    .qfg-select-all-label{display: flex; align-items: center; gap: 8px; font-size: 0.85rem; font-weight: 600; color: #334155; cursor: pointer; user-select: none;}
    .qfg-select-all-label input[type=checkbox]{width: 18px; height: 18px; cursor: pointer; accent-color: var(--primary-color); border-radius: 5px;}
    .qfg-sel-count{font-size: 0.8rem; font-weight: 700; color: #fff; background: linear-gradient(135deg, var(--primary-color) 0%, #0284c7 100%); padding: 4px 12px; border-radius: 14px; box-shadow: 0 2px 8px rgba(14, 165, 233, 0.3);}
    .tc-checkbox{width: 18px; height: 18px; cursor: pointer; accent-color: var(--primary-color); flex-shrink: 0; border-radius: 5px;}

        /* Enhanced Modern Styling */
        table { border-collapse: collapse; width: 100%; }
        table tbody tr { border-bottom: 1px solid rgba(226, 232, 240, 0.5); transition: background 0.2s ease; }
        table tbody tr:hover { background: rgba(14, 165, 233, 0.04); }
        table td, table th { padding: 12px 14px; text-align: left; font-size: 0.9rem; }
        table th { background: linear-gradient(135deg, rgba(248, 250, 252, 0.9) 0%, rgba(241, 245, 249, 0.8) 100%); font-weight: 700; color: #1e293b; border-bottom: 2px solid rgba(226, 232, 240, 0.6); }
        table td { color: #475569; }
        
        /* Scrollbar Styling */
        ::-webkit-scrollbar { width: 8px; height: 8px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(203, 213, 225, 0.5); border-radius: 4px; transition: all 0.2s; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(203, 213, 225, 0.8); }
        
        /* Badge and Tag Styles */
        .badge { display: inline-flex; align-items: center; padding: 0.2rem 0.7rem; border-radius: 8px; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; background: linear-gradient(135deg, rgba(248, 250, 252, 0.9) 0%, rgba(241, 245, 249, 0.8) 100%); color: #64748b; border: 1px solid rgba(226, 232, 240, 0.6); }
        .badge.primary { background: linear-gradient(135deg, rgba(14, 165, 233, 0.15) 0%, rgba(14, 165, 233, 0.08) 100%); color: var(--primary-color); border: 1px solid rgba(14, 165, 233, 0.3); }
        
        /* Input and Textarea Enhancements */
        input[type="text"], input[type="email"], input[type="password"], input[type="search"], textarea, select { 
            font-family: inherit; 
            transition: all 0.2s ease;
        }
        input::placeholder, textarea::placeholder { color: rgba(148, 163, 184, 0.7); }

        .tab-btn.active {
            color: #FFF !important;
            background: oklch(67.66% .1481 238.14) !important;
            border-radius: 10px 10px 0 0 !important;
        }
        .tab-content { display: none !important; }
        .tab-content.active { display: block !important; }

        .sidebar-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(15, 23, 42, 0.12);
            transition: all 0.2s ease;
        }
        .sidebar-btn:active {
            transform: translateY(0);
        }

        .save-action-btn {
            background: linear-gradient(135deg, #0ea5e9, #0284c7) !important;
            transition: all 0.2s ease;
            box-shadow: 0 4px 12px rgba(14, 165, 233, 0.25) !important;
        }
        .save-action-btn:hover {
            background: linear-gradient(135deg, #0284c7, #0369a1) !important;
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(14, 165, 233, 0.35) !important;
        }
        .save-action-btn:active {
            transform: translateY(0);
            box-shadow: 0 2px 8px rgba(14, 165, 233, 0.25) !important;
        }
        }

        #md-save-toast {
            position: fixed; 
            top: 1.5rem; 
            right: 1.5rem; 
            padding: 1rem 1.5rem; 
            border-radius: 14px;
            background: linear-gradient(135deg, #10b981, #059669); 
            color: white; 
            font-weight: 600; 
            font-size: 0.95rem; 
            z-index: 100000; 
            display: flex; 
            align-items: center; 
            gap: 0.75rem;
            box-shadow: 0 12px 32px rgba(16, 185, 129, 0.3), 0 0 1px rgba(0, 0, 0, 0.1); 
            transform: translateY(-30px); 
            opacity: 0; 
            visibility: hidden; 
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        #md-save-toast.show { 
            transform: translateY(0); 
            opacity: 1; 
            visibility: visible; 
        }
        #md-save-toast.error { 
            background: linear-gradient(135deg, #f43f5e, #e11d48); 
            box-shadow: 0 12px 32px rgba(244, 63, 94, 0.3), 0 0 1px rgba(0, 0, 0, 0.1);
        }
        #md-save-toast.info { 
            background: linear-gradient(135deg, #6366f1, #4f46e5); 
            box-shadow: 0 12px 32px rgba(99, 102, 241, 0.3), 0 0 1px rgba(0, 0, 0, 0.1);
        }
        
        /* Modified Indicator */
        .modified-indicator { 
            color: #f59e0b; 
            font-weight: 600; 
            font-size: 0.8rem; 
            margin-left: 0.4rem; 
            font-style: italic; 
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }

        /* Buttons */
        .btn-outline { background: transparent; border-color: rgba(226, 232, 240, 0.8); color: #64748b; }
        .btn-outline:hover { background: rgba(248, 250, 252, 0.9); color: var(--primary-color); border-color: var(--primary-color); }

        /* Modal Enhancements */
        .md-modal { background: #fff; border-radius: 18px; width: 100%; max-width: 800px; max-height: 90vh; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 20px 60px -12px rgba(15, 23, 42, 0.15), 0 0 1px rgba(0, 0, 0, 0.1); border: 1px solid rgba(226, 232, 240, 0.6); }
        .modal-header { padding: 1.5rem; border-bottom: 1px solid rgba(226, 232, 240, 0.5); display: flex; justify-content: space-between; align-items: center; background: linear-gradient(135deg, rgba(248, 250, 252, 0.9) 0%, rgba(241, 245, 249, 0.8) 100%); }
        .modal-header h3 { margin: 0; font-size: 1.15rem; font-weight: 700; color: #1e293b; letter-spacing: -0.5px; }
        .modal-body { padding: 1.75rem; overflow-y: auto; flex: 1; }
        .modal-footer { padding: 1.25rem 1.5rem; border-top: 1px solid rgba(226, 232, 240, 0.5); display: flex; justify-content: flex-end; gap: 0.75rem; background: linear-gradient(135deg, rgba(248, 250, 252, 0.5) 0%, rgba(241, 245, 249, 0.3) 100%); }
        .close-modal { background: none; border: none; font-size: 1.5rem; color: #94a3b8; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; width:36px; height:36px; border-radius:10px; }
        .close-modal:hover { color: #1e293b; background: rgba(226, 232, 240, 0.5); }

        /* Tree View (Hierarchy) Tab Styles — all levels always expanded */
        .tree-node { margin-left: 1.25rem; border-left: 1px solid #e2e8f0; padding-left: 0.75rem; margin-top: 0.25rem; }
        .tree-node.open > .tree-children { display: block; }
        .tree-node .tree-header { display: flex; align-items: center; justify-content: space-between; padding: 4px 8px; border-radius: 6px; transition: background 0.2s; }
        .tree-node .tree-header:hover { background: #f8fafc; }
        .tree-node .tree-actions { display: flex; gap: 0.75rem; opacity: 0; transition: opacity 0.2s; }
        .tree-node .tree-header:hover .tree-actions { opacity: 1; }
        .tree-node .tree-actions span { cursor: pointer; font-size: 0.75rem; color: var(--primary-color); }
        .tree-node .tree-actions span.danger { color: #ef4444; }
        .tree-node .tree-children { display: block; }
        .tree-node.open > .tree-children { display: block; }

        /* Toast Notification */
        #md-save-toast {
            position: fixed; top: 1.5rem; right: 1.5rem; padding: 1rem 1.5rem; border-radius: 12px;
            background: linear-gradient(135deg,#10b981,#059669); color: white; font-weight: 600; 
            font-size: 0.95rem; z-index: 100000; display: flex; align-items: center; gap: 0.75rem;
            box-shadow: 0 10px 25px rgba(0,0,0,0.15); transform: translateY(-20px); opacity: 0; 
            visibility: hidden; transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.1);
        }
        #md-save-toast.show { transform: translateY(0); opacity: 1; visibility: visible; }
        #md-save-toast.error { background: linear-gradient(135deg,#f43f5e,#e11d48); }
        #md-save-toast.info { background: linear-gradient(135deg,#6366f1,#4f46e5); }
        #md-editor-tabs .tab-btn{
            padding:0.5rem 0.8rem!important;
            border:none!important;
            color: #666!important;
            cursor:pointer;
            font-weight:600!important;
            background:transparent!important;
            box-shadow: none; 
            border-radius:0!important;
            margin-bottom:-2px; 
            text-transform: uppercase;
            letter-spacing: 0.05em; 
            transition: all 0.2s;
            font-size: 0.75rem;
        }
        #md-editor-tabs .tab-btn.active{
           color: #FFF !important;
            background: oklch(67.66% .1481 238.14) !important;
            border-radius: 10px 10px 0 0 !important;
        }
        .tc-list .tc-card {
            background: var(--bg-primary);
            padding: 1rem 1.25rem;
            border-radius: var(--border-radius);
            margin-bottom: 0.5rem;
            border: 1px solid var(--border-color);
            display: flex;
            gap: 1.5rem;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .tc-card h5 {
            color: #333;
            margin: 0;
            font-size: 0.85rem;
        }
        .qfg-bulk-action-head {
            display: flex;
            padding: 1rem;
            border: 1px solid #f0f0f0;
            gap: 1rem;
        }
        .tc-card .form-input {
            padding: 6px 10px !important;
            font-size: 0.7rem !important;
            font-weight: 500 !important;
        }
        .sidebar-btn-container {
            padding: 12px; 
            display: flex; 
            gap: 8px; border-bottom: 1px solid var(--border-color); 
            background: #fafafa;
        }
        .sidebar-btn-container .btn{
            color : #FFF !important;
        }
        .tc-card .fa{
            margin-right:0 !important;
            font-size: 0.6rem !important;
        }
        
        .qfg-bulk-group .qfg-tc-btn.btn, .project-header .qfg-tc-btn.btn, .suite-preview-block  .qfg-tc-btn.btn,
        .plan-preview-block .qfg-tc-btn.btn, .editor-header .btn.qfg-tc-btn{
            padding: 6px 12px !important;
            font-size: 0.8rem !important;
        }
        .qfg-bulk-group .btn {
            padding: 0.5rem !important;
        }
        .qfg-bulk-group .fa {
            margin-right: 0 !important;
            font-size: 0.6rem !important;
        }
    </style>

    <div class="editor-container" style="background: #f8fafc; padding: 0; display: flex; flex-direction: column;">
        <div id="md-save-toast">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
            <span id="md-save-toast-msg"></span>
        </div>
        
        <!-- Upload State -->
        <div id="uploadPrompt" class="upload-prompt">
            <div style="text-align: center; margin-bottom: 2.5rem;">
                <h2 style="font-size: 2rem; font-weight: 800; margin-bottom: 0.5rem; color: var(--text-primary);">Markdown Editor</h2>
                <p style="color: var(--text-secondary); font-size: 0.95rem;">Select how you want to open your project</p>
            </div>

            <div style="display: flex; gap: 1.5rem; justify-content: center; flex-wrap: wrap;">
                <!-- Open Folder Card -->
                <div class="upload-card" id="openFolderCard">
                    <div class="upload-icon-wrap" style="background: rgba(14,165,233,0.1);">
                        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#0ea5e9" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
                    </div>
                    <h3>Open Folder</h3>
                    <p>Import a folder containing multiple Markdown files.</p>
                    <div class="upload-card-btn" style="background: #0ea5e9; color: #fff; border-color: #0ea5e9;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
                        Choose Folder
                    </div>
                    <!-- NOTE: No hidden input here. window.selectFolder() handles this via showDirectoryPicker -->
                </div>
                <!-- Hidden fallback input (outside card so it does NOT intercept clicks) -->
                <input 
                    type="file" 
                    id="folderInput" 
                    multiple
                    webkitdirectory=""
                    style="display:none;"
                />

                <!-- Open File Card -->
                <div class="upload-card" onclick="document.getElementById(''fileInput'').click()">
                    <div class="upload-icon-wrap" style="background: rgba(16,185,129,0.1);">
                        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                    </div>
                    <h3>Open File</h3>
                    <p>Import individual Markdown files to edit.</p>
                    <div class="upload-card-btn" style="background: #fff; color: var(--text-primary); border-color: var(--border-color);">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                        Choose File
                    </div>
                    <input 
                        type="file" 
                        id="fileInput"
                        accept=".md,.markdown" 
                        multiple
                        style="position: absolute; top:0; left:0; width:100%; height:100%; opacity:0; cursor: pointer;"
                    />
                </div>
            </div>
        </div>

        <!-- Main Interface (Hidden initially) -->
        <div id="mainEditorArea" style="display: none;">
            <!-- Sidebar -->
            <aside class="tree-sidebar">
                <div class="tree-header">
                    <span style="display:flex;align-items:center;gap:6px;font-weight:700;font-size:0.88rem;color:#1e293b;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6366f1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M4.93 4.93a10 10 0 0 0 0 14.14"/></svg>
                        Explorer
                    </span>
                </div>
                <div class="sidebar-btn-container">
                    <button id="btnSidebarChange" title="Change Folder" class="sidebar-btn btn" style="background: #89c2dc4a !important;color: #0ea5e9 !important;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7v10a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-6l-2-2H5a2 2 0 0 0-2 2z"/></svg>
                    </button>
                    <button id="btnSidebarDownload" title="Download Project" class="sidebar-btn btn" style="background: #e0f0e5;color: #1ea388 !important;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" /><path d="M7 11l5 5l5 -5" /><path d="M12 4l0 12" /></svg>
                    </button>
                    <button id="btnSidebarClose" title="Close Project" class="sidebar-btn btn" style="color: #e11d48 !important;background: #e5d4d8a8;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 6l-12 12" /><path d="M6 6l12 12" /></svg>
                    </button>
                </div>
                <div id="folderTree" class="tree-content">
                    <!-- Tree Generated via JS -->
                </div>
            </aside>

            <!-- Main Content -->
            <main class="editor-main" style="flex-direction: column; display: flex;">

                <!-- Header Section: Fixed -->
                <div class="editor-header" style="border-bottom: 1px solid rgba(226, 232, 240, 0.6); flex-shrink: 0; background: linear-gradient(135deg, #fff 0%, #f8fafc 100%);">
                    <h1 style="font-size:0.9rem;margin:0;font-weight:700;letter-spacing:-0.01em;display:flex;align-items:center;color:#666 !important">
                        <i class="fas fa-file-invoice" style="margin-right:0.6rem;color:var(--primary-color);"></i>
                        <span id="editorFileTitle">Markdown Editor</span>
                    </h1>
                    <div style="display:flex;align-items:center;gap:1.5rem;">
                        <span id="totalTestCases" class="badge" style="padding: 0.3rem 0.9rem; font-size: 0.8rem;">0 Cases</span>
                        <button id="btnSaveFileAction" class="btn btn-primary qfg-tc-btn" style="padding:0rem 0.5rem !important; font-weight: 600;">
                            <i class="fas fa-save"></i> Save Changes
                        </button>
                    </div>
                </div>

                <!-- Tabs Section: Fixed -->
                <div id="md-editor-tabs" class="tabs" style="display:flex;padding:0 1rem;background:#fff;align-items:center;flex-wrap:wrap; border-bottom: 2px solid rgba(226, 232, 240, 0.6); flex-shrink: 0;margin: 1rem 0 0 0;">
                    <button class="tab-btn active" data-tab="preview"><i class="fa fa-eye"></i>Preview</button>
                    <button class="tab-btn" data-tab="treeView"><i class="fa fa-sitemap"></i>Hierarchy</button>
                    <button class="tab-btn" data-tab="markdown"><i class="fa fa-code"></i>Markdown</button>
                    <button class="tab-btn" data-tab="json"><i class="fa fa-sticky-note"></i>JSON</button>
                </div>

                <!-- Scrollable Content Area -->
                <div style="flex: 1; overflow-y: auto; display: flex; flex-direction: column;">
                    
                    <!-- Bulk Toolbar: Sticky -->
                    <div class="qfg-bulk-toolbar">
                      
                      <!-- Row 1: Selection | Divider | Actions | Divider | Properties | Spacer | Apply -->
                      <div class="qfg-bulk-row" style="border-bottom: 1px solid rgba(226, 232, 240, 0.4); padding-bottom: 12px; margin-bottom: 12px;">
                        <!-- Left: Selection -->
                        <div class="qfg-bulk-group">
                            <label class="qfg-select-all-label" style="display:flex;align-items:center;gap:8px;">
                              <input type="checkbox" id="selectAllTcs" style="width:16px;height:16px;">
                              <span style="font-weight:700;font-size: 0.7rem;">SELECT ALL</span>
                            </label>
                            <span id="selectedCountText" class="badge" style="background: linear-gradient(135deg, rgba(14, 165, 233, 0.1) 0%, rgba(14, 165, 233, 0.05) 100%); color:#0369a1; border:1px solid rgba(14, 165, 233, 0.3); padding: 0.25rem 0.75rem;">0 selected</span>
                        </div>

                        <div class="qfg-bulk-divider"></div>

                        <!-- Center-Left: Quick Edit -->
                        <div class="qfg-bulk-group">
                            <button id="bulkEditBtn" class="btn btn-sm  btn-edit-action">
                               <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                            </button>
                            <button id="bulkDeleteBtn" class="btn btn-sm btn-delete-action">
                                <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
                            </button>
                        </div>

                        <div class="qfg-bulk-divider"></div>

                        <!-- Center: Properties (Scenario/Exec) -->
                        <div class="qfg-bulk-group" style="gap:14px;">
                            <label class="qfg-bulk-label">Scenario</label>
                            <select id="bulkScenarioType" class="qfg-bulk-select">
                              <option value="">-- Scenario Type --</option>
                            </select>
                            <label class="qfg-bulk-label">Exec</label>
                            <select id="bulkExecutionType" class="qfg-bulk-select">
                              <option value="">-- Exec Type --</option>
                            </select>
                            <input type="text" id="bulkTags" class="qfg-bulk-input" placeholder="+ Tag" style="width: 110px; font-weight: 500;" />
                        </div>


                        <!-- Right: Assign/Prio Apply -->
                        <div class="qfg-bulk-group">
                            <select id="bulkAssignSelect" class="qfg-bulk-select" >
                              <option value="">-- Assignee --</option>
                            </select>
                            <select id="bulkPrioritySelect" class="qfg-bulk-select" >
                              <option value="">-- Prio --</option>
                              <option value="Critical">Critical</option>
                              <option value="High">High</option>
                              <option value="Medium">Medium</option>
                              <option value="Low">Low</option>
                            </select>
                            <button id="applyBulkActions" class="btn btn-sm btn-primary qfg-tc-btn">APPLY</button>
                        </div>
                      </div>

                      <!-- Row 2: Add Run | Spacer | Reset -->
                      <div class="qfg-bulk-row" style="padding-top: 0;">
                      <div class="qfg-bulk-spacer"></div>

                        <!-- Left: Run Config -->
                        <div class="qfg-bulk-group" style="gap:16px;">
                            <div style="display:flex;align-items:center;gap:10px;">
                                <label class="qfg-bulk-label" style="margin-bottom: 0;">Run Cycle</label>
                                <input type="text" id="bulkCycleName" value="1.0" class="qfg-bulk-input" style="width:70px; text-align:center; font-weight:700;" />
                            </div>
                            <div style="display:flex;align-items:center;gap:8px;position:relative;">
                                <input type="text" id="bulkCycleDateText" class="qfg-bulk-input qf-date" placeholder="MM-DD-YYYY" style="width: 140px; cursor:pointer; font-weight: 500;" />
                                <input type="hidden" id="bulkCycleDate" />
                                <i class="fas fa-calendar-alt" style="position: absolute; right: 10px; color: #94a3b8; font-size: 0.85rem; pointer-events: none;"></i>
                            </div>
                            <button id="applyBulkCycle" class="btn btn-sm btn-primary qfg-tc-btn">ADD</button>
                        </div>


                        <!-- Right: Reset Button -->
                        <button id="resetBulkActions" class="btn btn-sm qfg-tc-btn" style="background:linear-gradient(135deg, rgba(248,250,252,0.9), rgba(241,245,249,0.8)); border:1px solid rgba(226, 232, 240, 0.6); color:#64748b; padding: 6px 14px; font-weight: 600; font-size: 0.8rem; transition: all 0.2s;" title="Reset All Fields">
                            <i class="fas fa-undo"></i> Reset
                        </button>
                      </div>
                    </div>

                    <!-- Main Content: Scrollable -->
                    <div style="flex: 1; overflow-y: auto; padding: 24px;">
                        <!-- Test Cases Table -->

                    <!-- Results.js targets this -->
                    <div class="tab-content active" id="preview" style="display: block;">
                        <div id="testCasesPreview" style="padding: 0;">
                            <!-- Empty state header -->
                            <div style="margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 1px solid rgba(226, 232, 240, 0.6); margin-top: 0;">
                                <h2 style="color: #0ea5e9; font-size: 1.1rem; font-weight: 700; margin: 0;">Test Cases</h2>
                            </div>
                            <!-- Centered icon empty state -->
                            <div style="text-align: center; color: var(--text-muted); padding-top: 5rem; padding-bottom: 5rem;">
                                <i class="fas fa-file-invoice" style="font-size: 3rem; opacity: 0.3; margin-bottom: 1rem;"></i>
                                <p style="font-size: 0.9rem; color:#94a3b8;">Select a Markdown file from the sidebar to view and edit schemas.</p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="tab-content" id="treeView" style="display: none; padding: 0;">
                        <div id="treeViewContent" style="padding: 1.5rem;"></div>
                    </div>
                    
                    <div class="tab-content" id="markdown" style="display: none; padding: 0;">
                        <textarea id="markdownContent" style="width: 100%; height: 600px; background: var(--bg-card); color: var(--text-primary); border: 1px solid rgba(226, 232, 240, 0.6); padding: 1rem; font-family: Monaco, Menlo, Ubuntu Mono, monospace; resize: none; border-radius: 0; margin: 0;"></textarea>
                    </div>
                    
                    <div class="tab-content" id="json" style="display: none; padding: 0;">
                        <pre id="jsonContent" style="background: var(--bg-card); color: var(--text-primary); padding: 1.5rem; overflow: auto; max-height: 600px; border-radius: 0; margin: 0; font-family: Monaco, Menlo, Ubuntu Mono, monospace; font-size: 0.85rem;"></pre>
                    </div>
                    </div>
                </div>
            </main>
        </div>

    <!-- Modals (Copied from Results page for editing functionality) -->
    
    <!-- Edit TC Modal -->
    <div id="editModal" class="modal-overlay">
        <div class="md-modal">
            <div class="modal-header">
                <h3>Edit Test Case</h3>
                <button class="close-modal" id="closeModal">&times;</button>
            </div>
            <div class="modal-body">
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>ID (@id)</label>
                        <input type="text" id="editTcId" class="form-input" placeholder="e.g. TC-001" />
                    </div>
                    <div class="form-group">
                        <label>Requirement ID</label>
                        <input type="text" id="editTcReqId" class="form-input" placeholder="e.g. REQ-123" />
                    </div>
                </div>
                <div class="form-group">
                    <label>Title</label>
                    <input type="text" id="editTcTitle" class="form-input" />
                </div>
                <div class="form-group">
                    <label>Steps</label>
                    <textarea id="editTcSteps" class="form-input" rows="5"></textarea>
                </div>
                <div class="form-group">
                    <label>Expected Result</label>
                    <textarea id="editTcExpected" class="form-input" rows="3"></textarea>
                </div>
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Scenario Type</label>
                        <div style="display: flex; gap: 0.5rem;">
                            <input type="text" id="editTcScenarioType" class="form-input" placeholder="e.g. Happy Path" style="flex: 1; min-width: 120px;" />
                            <select id="editTcScenarioTypeSelect" class="form-input" style="width: auto;">
                                <option value="">Select</option>
                                <option value="Happy Path">Happy Path</option>
                                <option value="Negative">Negative</option>
                                <option value="Boundary">Boundary</option>
                                <option value="Security">Security</option>
                                <option value="Performance">Performance</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Execution Type</label>
                        <div style="display: flex; gap: 0.5rem;">
                            <input type="text" id="editTcExecutionType" class="form-input" placeholder="e.g. Manual" style="flex: 1; min-width: 120px;" />
                            <select id="editTcExecutionTypeSelect" class="form-input" style="width: auto;">
                                <option value="">Select</option>
                                <option value="Manual">Manual</option>
                                <option value="Automated">Automated</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="form-group">
                    <label>Tags</label>
                    <div style="display: flex; gap: 0.5rem;">
                        <input type="text" id="editTcTags" class="form-input" style="flex: 1; min-width: 120px;" />
                        <select id="editTcTagsSelect" class="form-input" style="width: auto;">
                            <option value="">+ Add</option>
                        </select>
                    </div>
                </div>
                <div class="evidence-section" style="border-top: 1px solid var(--border-color); padding-top: 1rem;">
                     <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                         <h4 style="margin:0;">Evidence History</h4>
                         <button type="button" id="addEvidenceRowBtn" style="background:#eff6ff; color:#1e40af; border:1px solid #bfdbfe; border-radius:999px; padding:4px 12px; font-size:0.75rem; font-weight:600; cursor:pointer;">+ Add Evidence</button>
                     </div>
                     <div id="evidenceListContainer"></div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" id="cancelEdit">Cancel</button>
                <button class="btn btn-primary" id="saveEdit">Save</button>
            </div>
        </div>
    </div>
    
    <!-- Bulk Edit Modal -->
    <div id="bulkEditModal" class="modal-overlay">
        <div class="md-modal">
            <div class="modal-header">
                <h3>Bulk Edit Selected Cases</h3>
                <button class="close-modal" id="closeBulkEdit">&times;</button>
            </div>
            <div class="modal-body">
                <p style="margin-bottom: 1rem; color: var(--text-muted); font-size: 0.9rem;">Changes will be applied to all selected test cases. Leave fields empty to keep existing values.</p>
                
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Assignee</label>
                        <select id="bulkEditAssignee" class="form-input">
                            <option value="">-- No Change --</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Priority</label>
                        <select id="bulkEditPriority" class="form-input">
                            <option value="">-- No Change --</option>
                            <option value="Critical">Critical</option>
                            <option value="High">High</option>
                            <option value="Medium">Medium</option>
                            <option value="Low">Low</option>
                        </select>
                    </div>
                </div>

                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Scenario Type</label>
                        <div style="display: flex; gap: 0.5rem;">
                            <input type="text" id="bulkEditScenarioType" class="form-input" placeholder="No Change" style="flex: 1; min-width: 120px;" />
                            <select id="bulkEditScenarioTypeSelect" class="form-input" style="width: auto;">
                                <option value="">Select</option>
                                <option value="Happy Path">Happy Path</option>
                                <option value="Negative">Negative</option>
                                <option value="Boundary">Boundary</option>
                                <option value="Security">Security</option>
                                <option value="Performance">Performance</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Execution Type</label>
                        <div style="display: flex; gap: 0.5rem;">
                            <input type="text" id="bulkEditExecutionType" class="form-input" placeholder="No Change" style="flex: 1; min-width: 120px;" />
                            <select id="bulkEditExecutionTypeSelect" class="form-input" style="width: auto;">
                                <option value="">Select</option>
                                <option value="Manual">Manual</option>
                                <option value="Automated">Automated</option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label>Add Tags (comma separated)</label>
                    <div style="display: flex; gap: 0.5rem;">
                        <input type="text" id="bulkEditTags" class="form-input" placeholder="e.g. Functional, Login" style="flex: 1;" />
                        <select id="bulkEditTagsSelect" class="form-input" style="width: auto;">
                            <option value="">+ Add Tag</option>
                        </select>
                    </div>
                    <p style="font-size: 0.75rem; color: var(--text-muted); margin-top: 0.25rem;">New tags will be appended to existing ones.</p>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" id="cancelBulkEdit">Cancel</button>
                <button class="btn btn-primary" id="saveBulkEdit">Apply Changes</button>
            </div>
        </div>
    </div>
    <div id="planEditModal" class="modal-overlay">
        <div class="md-modal">
            <div class="modal-header">
                <h3>Edit Plan</h3>
                <button class="close-modal" id="closePlanEdit">&times;</button>
            </div>
            <div class="modal-body">
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="editPlanName" class="form-input" />
                    </div>
                    <div class="form-group">
                        <label>Plan ID</label>
                        <input type="text" id="editPlanId" class="form-input" />
                    </div>
                </div>
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Plan Date</label>
                        <div style="display: flex; align-items: center; position: relative;">
                            <input type="text" id="editPlanDate" class="form-input qf-date" placeholder="MM-DD-YYYY" style="width: 100%; cursor: pointer;" />
                            <input type="hidden" id="editPlanDateIso" />
                            <i class="fas fa-calendar-alt" style="position: absolute; right: 10px; pointer-events: none; color: #94a3b8; font-size: 0.9rem;"></i>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Created By</label>
                        <select id="editPlanCreatedBy" class="form-input"></select>
                    </div>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea id="editPlanDescription" class="form-input" rows="4"></textarea>
                </div>
                <div class="form-group">
                    <label>Metadata (YAML)</label>
                    <textarea id="editPlanYaml" class="form-input" rows="4"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" id="cancelPlanEdit">Cancel</button>
                <button class="btn btn-primary" id="savePlanEdit">Save</button>
            </div>
        </div>
    </div>

    <!-- Suite Edit Modal -->
    <div id="suiteEditModal" class="modal-overlay">
        <div class="md-modal">
            <div class="modal-header">
                <h3>Edit Suite</h3>
                <button class="close-modal" id="closeSuiteEdit">&times;</button>
            </div>
            <div class="modal-body">
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Suite Name</label>
                        <input type="text" id="editSuiteName" class="form-input" />
                    </div>
                    <div class="form-group">
                        <label>Suite ID</label>
                        <input type="text" id="editSuiteId" class="form-input" />
                    </div>
                </div>
                <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                    <div class="form-group">
                        <label>Suite Date</label>
                        <div style="display: flex; align-items: center; position: relative;">
                            <input type="text" id="editSuiteDate" class="form-input qf-date" placeholder="MM-DD-YYYY" style="width: 100%; cursor: pointer;" />
                            <input type="hidden" id="editSuiteDateIso" />
                            <i class="fas fa-calendar-alt" style="position: absolute; right: 10px; pointer-events: none; color: #94a3b8; font-size: 0.9rem;"></i>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Created By</label>
                        <select id="editSuiteCreatedBy" class="form-input"></select>
                    </div>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea id="editSuiteDescription" class="form-input" rows="4"></textarea>
                </div>
                <div class="form-group">
                    <label>Metadata (YAML)</label>
                    <textarea id="editSuiteYaml" class="form-input" rows="4"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" id="cancelSuiteEdit">Cancel</button>
                <button class="btn btn-primary" id="saveSuiteEdit">Save</button>
            </div>
        </div>
    </div>


</div>
</div>
</div>
' AS html;